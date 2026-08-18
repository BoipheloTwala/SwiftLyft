const jwt = require('jsonwebtoken');

// Generate access token
const generateAccessToken = (userId) => {
  return jwt.sign(
    { userId, type: 'access' },
    process.env.JWT_SECRET,
    { 
      expiresIn: process.env.JWT_EXPIRE || '24h',
      issuer: 'swiftlyft-api',
      audience: 'swiftlyft-app'
    }
  );
};

// Generate refresh token
const generateRefreshToken = (userId) => {
  return jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_REFRESH_SECRET,
    { 
      expiresIn: process.env.JWT_REFRESH_EXPIRE || '7d',
      issuer: 'swiftlyft-api',
      audience: 'swiftlyft-app'
    }
  );
};

// Verify refresh token
const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
};

// Generate both tokens
const generateTokenPair = (userId) => {
  const accessToken = generateAccessToken(userId);
  const refreshToken = generateRefreshToken(userId);
  
  return {
    accessToken,
    refreshToken,
    expiresIn: process.env.JWT_EXPIRE || '24h'
  };
};

// Decode token without verification (for debugging)
const decodeToken = (token) => {
  return jwt.decode(token);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  generateTokenPair,
  decodeToken
};