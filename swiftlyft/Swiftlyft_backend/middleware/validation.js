const { body, validationResult } = require('express-validator');

// Standardized API response format
const sendResponse = (res, statusCode, success, message, data = null, errors = null) => {
  const response = {
    success,
    message,
    ...(data && { data }),
    ...(errors && { errors })
  };
  
  return res.status(statusCode).json(response);
};

// Validation middleware
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendResponse(res, 400, false, 'Validation failed', null, errors.array());
  }
  next();
};

// Common validation rules
const emailValidation = body('email')
  .isEmail()
  .normalizeEmail()
  .withMessage('Please provide a valid email address');

const passwordValidation = body('password')
  .isLength({ min: 8 })
  .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/)
  .withMessage('Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number');

const phoneValidation = body('phoneNumber')
  .optional()
  .matches(/^\+?[1-9]\d{1,14}$/)
  .withMessage('Please provide a valid phone number');

const coordinateValidation = (field) => body(field)
  .isFloat({ min: -90, max: 90 })
  .withMessage(`${field} must be a valid latitude between -90 and 90`);

const longitudeValidation = (field) => body(field)
  .isFloat({ min: -180, max: 180 })
  .withMessage(`${field} must be a valid longitude between -180 and 180`);

// Error handling middleware
const handleAsyncErrors = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Standard error responses
const errorResponses = {
  notFound: (res, resource = 'Resource') => 
    sendResponse(res, 404, false, `${resource} not found`),
  
  unauthorized: (res, message = 'Unauthorized access') => 
    sendResponse(res, 401, false, message),
  
  forbidden: (res, message = 'Access forbidden') => 
    sendResponse(res, 403, false, message),
  
  badRequest: (res, message = 'Bad request') => 
    sendResponse(res, 400, false, message),
  
  serverError: (res, message = 'Internal server error') => 
    sendResponse(res, 500, false, message),
  
  conflict: (res, message = 'Resource conflict') => 
    sendResponse(res, 409, false, message)
};

module.exports = {
  sendResponse,
  validateRequest,
  emailValidation,
  passwordValidation,
  phoneValidation,
  coordinateValidation,
  longitudeValidation,
  handleAsyncErrors,
  errorResponses
};
