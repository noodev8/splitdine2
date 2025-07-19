# Receipt Parsing Documentation

This document describes the SplitDine receipt scanning and parsing system, including testing framework and improvement guidelines.

## Overview

SplitDine uses Google Vision API for OCR text extraction and custom parsing logic to extract menu items, prices, and totals from restaurant receipts.

## Architecture

### Components
- **Google Vision OCR** (`splitdine2_server/utils/ocrService.js`)
- **Receipt Parsing Logic** (`parseReceiptText` function)
- **API Endpoints** (`splitdine2_server/routes/receipt_scan.js`)
- **Debug/Testing Framework** (New debug endpoint and test script)

### Flow
1. **Image Upload** → Temporary file storage
2. **Google Vision OCR** → Raw text extraction with confidence scores
3. **Text Parsing** → Extract items, prices, totals
4. **Database Storage** → Save results in `receipt_scans` table
5. **Frontend Display** → Show editable results to user

## Google Vision OCR Integration

### Configuration
- **Service Account**: `docs/splitdine-ocr-6921886ed122.json`
- **API Client**: `@google-cloud/vision` ImageAnnotatorClient
- **Method**: `textDetection()` - general text detection

### OCR Output Structure
```javascript
{
  success: true/false,
  text: "FULL OCR TEXT FROM RECEIPT...",
  confidence: 0.85,           // Average confidence (0.0-1.0)
  detections: [...]          // Individual text detections from Vision API
}
```

### Confidence Calculation
- Averages confidence scores from all detected text elements
- Falls back to 0.8 if no confidence data available
- Rounds to 2 decimal places

## Receipt Parsing Logic

### Current Parser Strategy (`parseReceiptText`)

#### Line Processing
1. **Split text by newlines** and trim/uppercase each line
2. **Classify each line** as: SKIP, TOTAL, TAX, SERVICE, or ITEM
3. **Extract prices** using regex: `/([\d,]+\.\d{2})$/`
4. **Handle multi-line items** (name on one line, price on next)

#### Price Pattern Matching
- **Regex**: `/([\d,]+\.\d{2})$/` 
- **Matches**: `12.00`, `1,234.50`, `45.99`
- **Position**: End of line only
- **Decimal**: Must have exactly 2 decimal places

#### Line Classification Rules

**SKIP Lines** (Non-items):
```
THANK, ORDER, STATION, TOTAL, TAX, GRATUITY, PARTIES, PLEASE
CHECK OUT ONLINE, RECOMMENDING US, SERV #\d+, A\d+, C\d+, \d{2}:\d{2}
```

**TOTAL Lines**: Start with "TOTAL"
**TAX Lines**: Start with "TAX"  
**SERVICE Lines**: Contain "SERVICE" or "GRATUITY"
**ITEM Lines**: Everything else

#### Item Name Processing

**Quantity Extraction**:
- If line starts with number + space + text: extract quantity
- Example: "2 CHICKEN BURGER" → quantity=2, name="CHICKEN BURGER"

**Text Cleaning**:
- Remove `%` and `"` characters
- Apply OCR corrections (see below)
- Trim whitespace

**OCR Text Corrections**:
```javascript
CHCKN → CHICKEN
TRKY → TURKEY
BRGR → BURGER
CHCK% → CHICKEN
POT PIE → POT PIE
ROAST CHCK → ROAST CHICKEN
IL LEMONADE → LEMONADE
```

#### Multi-line Item Handling

**Pattern 1**: Name and price on same line
```
CHICKEN BURGER        12.50
```

**Pattern 2**: Name on one line, price on next
```
CHICKEN BURGER
12.50
```

**Pattern 3**: Name only (price missing/unclear)
```
CHICKEN BURGER
(no price found - defaults to 0.00)
```

### Parser Output Structure
```javascript
{
  success: true/false,
  items: [
    {
      quantity: 1,
      name: "CHICKEN BURGER", 
      price: 12.50
    }
  ],
  totals: {
    total_amount: 45.67,
    tax_amount: 3.50,
    service_charge: 5.00
  }
}
```

## Testing Framework

### Debug Endpoint
**Endpoint**: `POST /api/receipt_scan/debug`
- **Authentication**: None required (testing only)
- **Input**: multipart/form-data with image file
- **Output**: Complete OCR + parsing data

### Debug Output
```javascript
{
  return_code: 'SUCCESS',
  data: {
    filename: "receipt.jpg",
    filesize: 2048576,
    ocr_result: {
      success: true,
      text: "RAW OCR TEXT...",
      confidence: 0.85,
      detections: [...]
    },
    parse_result: {
      success: true,
      items: [...],
      totals: {...}
    },
    timestamp: "2024-01-15T10:30:45.123Z"
  }
}
```

### File Logging
- **Location**: `splitdine2_server/debug_receipts/`
- **Format**: `receipt_debug_YYYY-MM-DDTHH-mm-ss-sssZ.json`
- **Content**: Complete debug data (OCR + parsing results)

### Test Script Usage
```bash
# Start server
cd splitdine2_server && npm run dev

# Test a receipt
node test_receipt_debug.js path/to/receipt.jpg

# Check results
# - Console shows summary
# - Full JSON saved to debug_receipts/
# - Server logs show processing details
```

## Known Issues & Improvement Areas

### Current Parser Limitations

1. **Price Pattern Too Strict**
   - Only matches prices at end of line
   - Misses: "BURGER $12.50 COMBO" format
   - Misses: prices with spaces "12. 50"

2. **Line Classification Over-Broad**
   - SKIP rules may exclude valid items
   - No handling for item codes/descriptions

3. **Multi-line Logic Gaps**
   - Doesn't handle items spanning 3+ lines
   - No support for item modifiers/options

4. **OCR Corrections Incomplete**
   - Limited hardcoded replacements
   - No fuzzy matching for similar words

5. **Total Detection Issues**
   - May miss subtotals vs final totals
   - No handling for multiple tax types

### Testing Data Needed

To improve the parser, test with:
- **Fast food receipts** (McDonald's, KFC, etc.)
- **Sit-down restaurant receipts** 
- **Food delivery receipts** (DoorDash, Uber Eats)
- **Coffee shop receipts** (Starbucks, local cafes)
- **Grocery receipts** (if applicable)
- **International receipts** (different formats)

### Improvement Process

1. **Collect Test Data**: Use debug endpoint to gather OCR/parsing results
2. **Analyze Patterns**: Review debug JSON files for common failure modes
3. **Update Parser Rules**: Modify classification and extraction logic
4. **Add OCR Corrections**: Expand text replacement rules
5. **Test & Iterate**: Repeat with same receipts to verify improvements

## Database Schema

### `receipt_scans` Table
```sql
CREATE TABLE public.receipt_scans (
    id integer PRIMARY KEY,
    session_id integer NOT NULL,
    image_path text NOT NULL,
    ocr_text text,                     -- Full OCR text
    ocr_confidence numeric(3,2),       -- 0.00-1.00 confidence
    parsed_items jsonb,                -- JSON array of items
    total_amount numeric(10,2),        -- Extracted total
    tax_amount numeric(10,2),          -- Extracted tax
    service_charge numeric(10,2),      -- Extracted service charge
    processing_status varchar(20),     -- pending/processing/completed/failed
    uploaded_by_user_id integer,
    created_at timestamp,
    updated_at timestamp
);
```

## API Endpoints

### Production Endpoint
`POST /api/receipt_scan/upload`
- Requires authentication
- Creates database records
- Returns parsed items for user editing

### Debug Endpoint  
`POST /api/receipt_scan/debug`
- No authentication required
- Returns complete debug data
- Saves JSON files for analysis

## Future Improvements

### Short-term (Parser Logic)
- Expand price regex patterns
- Add more OCR text corrections
- Improve line classification rules
- Better multi-line item detection

### Medium-term (Intelligence)
- Machine learning for item classification
- Fuzzy string matching for corrections
- Context-aware parsing (restaurant type)
- Confidence scoring for parsed items

### Long-term (Advanced)
- Multiple OCR providers (fallback/comparison)
- Image preprocessing (rotation, contrast)
- Receipt format auto-detection
- User feedback learning system

## Development Guidelines

### Testing New Parsing Logic
1. Always test with debug endpoint first
2. Save original debug JSON files before changes
3. Test with diverse receipt types
4. Verify no regressions on previous receipts
5. Update this documentation with new rules

### Adding OCR Corrections
- Add to `parseReceiptText` function
- Use common OCR error patterns
- Test against existing debug data
- Consider regex for pattern-based corrections

### Modifying Classification Rules
- Be careful not to over-exclude items
- Test edge cases (item names containing keywords)
- Consider receipt-specific vs universal rules
- Document new classification patterns

---

*Last updated: 2024-01-15*
*Version: 1.0*