const crypto = require('crypto');

const generateToken = (prefix = '') => {
  const randomBytes = crypto.randomBytes(32).toString('hex');
  return prefix ? `${prefix}_${randomBytes}` : randomBytes;
};

const isTokenExpired = (expiryDate) => {
  return new Date() > new Date(expiryDate);
};

const getTokenExpiry = (hours = 24) => {
  const date = new Date();
  date.setHours(date.getHours() + hours);
  return date;
};

module.exports = {
  generateToken,
  isTokenExpired,
  getTokenExpiry
};