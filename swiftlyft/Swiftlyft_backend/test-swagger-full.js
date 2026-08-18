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
        url: process.env.NODE_ENV === 'production'
          ? 'https://api.swiftlyft.co.za/api'
          : 'http://localhost:3000/api',
        description: process.env.NODE_ENV === 'production' ? 'Production server' : 'Development server'
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

try {
  const specs = swaggerJSDoc(options);
  console.log('Paths found:', Object.keys(specs.paths || {}).length);
  if (specs.paths && Object.keys(specs.paths).length > 0) {
    console.log('Sample paths:', Object.keys(specs.paths).slice(0, 10));
  } else {
    console.log('No paths found');
  }
} catch (error) {
  console.error('Error:', error.message);
}
