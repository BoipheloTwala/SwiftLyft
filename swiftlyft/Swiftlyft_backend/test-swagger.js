const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SwiftLyft API',
      version: '1.0.0',
      description: 'Test API'
    }
  },
  apis: ['./docs/swagger-examples.js']
};

try {
  const specs = swaggerJSDoc(options);
  console.log('Paths found:', Object.keys(specs.paths || {}).length);
  if (specs.paths && Object.keys(specs.paths).length > 0) {
    console.log('Sample paths:', Object.keys(specs.paths).slice(0, 5));
  } else {
    console.log('No paths found');
  }
} catch (error) {
  console.error('Error:', error.message);
}
