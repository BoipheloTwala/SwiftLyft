const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SwiftLyft API',
      version: '1.0.0',
      description: 'A comprehensive ride-sharing and logistics platform backend API',
      contact: {
        name: 'SwiftLyft Team',
        email: 'support@swiftlyft.co.za'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'https://swiftlyft-frontend.onrender.com',
        description: 'Production server'
      },
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT token for authentication'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'User ID'
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address'
            },
            name: {
              type: 'string',
              description: 'User full name'
            },
            phoneNumber: {
              type: 'string',
              description: 'User phone number'
            },
            role: {
              type: 'string',
              enum: ['user', 'admin'],
              description: 'User role'
            },
            loyaltyTier: {
              type: 'string',
              enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'],
              description: 'Loyalty program tier'
            },
            loyaltyPoints: {
              type: 'number',
              description: 'Current loyalty points'
            },
            isActive: {
              type: 'boolean',
              description: 'Whether the user account is active'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp'
            }
          }
        },
        Vehicle: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'Vehicle ID'
            },
            vehicleId: {
              type: 'string',
              description: 'Unique vehicle identifier'
            },
            name: {
              type: 'string',
              description: 'Vehicle name'
            },
            make: {
              type: 'string',
              description: 'Vehicle manufacturer'
            },
            model: {
              type: 'string',
              description: 'Vehicle model'
            },
            year: {
              type: 'number',
              description: 'Vehicle year'
            },
            category: {
              type: 'string',
              enum: ['sedan', 'suv', 'luxury', 'van', 'truck'],
              description: 'Vehicle category'
            },
            passengerCapacity: {
              type: 'number',
              description: 'Maximum passenger capacity'
            },
            status: {
              type: 'string',
              enum: ['available', 'busy', 'offline', 'maintenance'],
              description: 'Current vehicle status'
            },
            currentLocation: {
              type: 'object',
              properties: {
                address: {
                  type: 'string',
                  description: 'Current location address'
                },
                coordinates: {
                  type: 'object',
                  properties: {
                    latitude: {
                      type: 'number',
                      description: 'Latitude coordinate'
                    },
                    longitude: {
                      type: 'number',
                      description: 'Longitude coordinate'
                    }
                  }
                }
              }
            },
            pricing: {
              type: 'object',
              properties: {
                baseFare: {
                  type: 'number',
                  description: 'Base fare amount'
                },
                perKmRate: {
                  type: 'number',
                  description: 'Rate per kilometer'
                },
                perMinuteRate: {
                  type: 'number',
                  description: 'Rate per minute'
                },
                minimumFare: {
                  type: 'number',
                  description: 'Minimum fare amount'
                },
                currency: {
                  type: 'string',
                  description: 'Currency code'
                }
              }
            }
          }
        },
        Booking: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'Booking ID'
            },
            bookingId: {
              type: 'string',
              description: 'Unique booking identifier'
            },
            userId: {
              type: 'string',
              description: 'User ID who made the booking'
            },
            driverId: {
              type: 'string',
              description: 'Driver ID assigned to the booking'
            },
            vehicleId: {
              type: 'string',
              description: 'Vehicle ID assigned to the booking'
            },
            pickupLocation: {
              type: 'object',
              properties: {
                address: {
                  type: 'string',
                  description: 'Pickup address'
                },
                coordinates: {
                  type: 'object',
                  properties: {
                    latitude: {
                      type: 'number',
                      description: 'Pickup latitude'
                    },
                    longitude: {
                      type: 'number',
                      description: 'Pickup longitude'
                    }
                  }
                }
              }
            },
            dropoffLocation: {
              type: 'object',
              properties: {
                address: {
                  type: 'string',
                  description: 'Dropoff address'
                },
                coordinates: {
                  type: 'object',
                  properties: {
                    latitude: {
                      type: 'number',
                      description: 'Dropoff latitude'
                    },
                    longitude: {
                      type: 'number',
                      description: 'Dropoff longitude'
                    }
                  }
                }
              }
            },
            passengerCount: {
              type: 'number',
              description: 'Number of passengers'
            },
            pricing: {
              type: 'object',
              properties: {
                baseFare: {
                  type: 'number',
                  description: 'Base fare amount'
                },
                distanceFare: {
                  type: 'number',
                  description: 'Distance-based fare'
                },
                timeFare: {
                  type: 'number',
                  description: 'Time-based fare'
                },
                total: {
                  type: 'number',
                  description: 'Total fare amount'
                },
                currency: {
                  type: 'string',
                  description: 'Currency code'
                }
              }
            },
            status: {
              type: 'string',
              enum: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled', 'expired', 'disputed'],
              description: 'Current booking status'
            },
            scheduledDate: {
              type: 'string',
              format: 'date-time',
              description: 'Scheduled pickup time'
            },
            paymentStatus: {
              type: 'string',
              enum: ['pending', 'paid', 'failed', 'refunded'],
              description: 'Payment status'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Booking creation timestamp'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            message: {
              type: 'string',
              description: 'Error message'
            },
            errors: {
              type: 'array',
              items: {
                type: 'object'
              },
              description: 'Validation errors'
            }
          }
        },
        Success: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              description: 'Success message'
            },
            data: {
              type: 'object',
              description: 'Response data'
            }
          }
        }
      },
      responses: {
        UnauthorizedError: {
          description: 'Authentication information is missing or invalid',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                message: 'Access token required'
              }
            }
          }
        },
        NotFoundError: {
          description: 'The specified resource was not found',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                message: 'Resource not found'
              }
            }
          }
        },
        BadRequestError: {
          description: 'Bad request - invalid input data',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                message: 'Validation failed',
                errors: [
                  {
                    field: 'email',
                    message: 'Please provide a valid email address'
                  }
                ]
              }
            }
          }
        },
        ForbiddenError: {
          description: 'Access forbidden - insufficient permissions',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                message: 'Access forbidden'
              }
            }
          }
        },
        InternalServerError: {
          description: 'Internal server error',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                message: 'Internal server error'
              }
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: [
    './routes/*.js',
    './models/*.js',
    './docs/swagger-examples.js'
  ]
};

const specs = swaggerJSDoc(options);

module.exports = specs;