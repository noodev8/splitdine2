-- Update a user to have admin privileges
-- Replace 'your-email@example.com' with your actual email

UPDATE app_user 
SET admin = true 
WHERE email = 'your-email@example.com';

-- Verify the update
SELECT id, email, display_name, admin 
FROM app_user 
WHERE email = 'your-email@example.com';