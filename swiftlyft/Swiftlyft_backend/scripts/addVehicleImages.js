const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
require('dotenv').config();

/**
 * Script to add images to vehicle listings
 * Can add images to specific vehicles or all vehicles
 */
class VehicleImageAdder {
  constructor() { this.connection = null; }

  async connect() {
    // Force connection to vehicles database
    const mongoUri = 'mongodb://localhost:27017/swiftlyft_vehicles';
    this.connection = await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ Connected to MongoDB for adding vehicle images');
    console.log(`📊 Database: ${mongoose.connection.name}`);
    console.log(`🔗 URI: ${mongoUri}`);
  }

  async disconnect() {
    if (this.connection) {
      await mongoose.disconnect();
      console.log('✅ Disconnected from MongoDB');
    }
  }

  // Vehicle-specific image sets
  getVehicleImages(vehicle) {
    const make = vehicle.make.toLowerCase();
    const model = vehicle.model.toLowerCase();

    // Audi A4 images
    if (make === 'audi' && model.includes('a4')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1597007030739-6d2e7172ee5b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2070',
        imageGallery: [
          'https://images.unsplash.com/photo-1597007030739-6d2e7172ee5b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2070',
          'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1597007030739-6d2e7172ee5b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2070',
            'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // BMW 3 Series images
    if (make === 'bmw' && model.includes('3')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // Toyota Corolla images
    if (make === 'toyota' && model.includes('corolla')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // VW Tiguan images
    if (make === 'vw' && model.includes('tiguan')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // Mercedes Vito images
    if (make === 'mercedes' && model.includes('vito')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // Tesla Model 3 images
    if (make === 'tesla' && model.includes('model 3')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // Toyota Prius images
    if (make === 'toyota' && model.includes('prius')) {
      return {
        imageUrl: 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&h=600&fit=crop',
        imageGallery: [
          'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop'
        ],
        images: {
          exterior: [
            'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
          ],
          interior: [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
            'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
          ],
          documents: []
        }
      };
    }

    // Default fallback images for any other vehicles
    return {
      imageUrl: 'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
      imageGallery: [
        'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
        'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop'
      ],
      images: {
        exterior: [
          'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1597404294360-feeeda04612e?w=800&h=600&fit=crop'
        ],
        interior: [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1549399735-cef2e2c3f638?w=800&h=600&fit=crop'
        ],
        documents: []
      }
    };
  }

  async addImagesToAllVehicles({ skipIfExists = true } = {}) {
    try {
      console.log('🔍 Finding all vehicles...');

      const query = skipIfExists ? { imageUrl: { $in: [null, ''] } } : {};
      const vehicles = await Vehicle.find(query).limit(50); // Limit to avoid overwhelming

      if (vehicles.length === 0) {
        console.log('ℹ️ No vehicles found that need images');
        return;
      }

      console.log(`📋 Found ${vehicles.length} vehicle(s) to process`);

      let successCount = 0;
      let errorCount = 0;

      for (const vehicle of vehicles) {
        try {
          console.log(`🎯 Processing: ${vehicle.name} (${vehicle.make} ${vehicle.model})`);

          const images = this.getVehicleImages(vehicle);

          const updatedVehicle = await Vehicle.findByIdAndUpdate(
            vehicle._id,
            { $set: images },
            { new: true, runValidators: true }
          );

          if (updatedVehicle) {
            console.log(`✅ Added images to ${vehicle.name}`);
            successCount++;
          } else {
            console.log(`❌ Failed to update ${vehicle.name}`);
            errorCount++;
          }
        } catch (error) {
          console.error(`❌ Error processing ${vehicle.name}:`, error.message);
          errorCount++;
        }
      }

      console.log(`\n📊 Summary:`);
      console.log(`✅ Successfully updated: ${successCount} vehicles`);
      console.log(`❌ Failed to update: ${errorCount} vehicles`);

    } catch (error) {
      console.error('❌ Error adding images to vehicles:', error);
      throw error;
    }
  }

  async addImagesToAudiA4() {
    try {
      console.log('🔍 Searching for Audi A4 vehicles...');

      const audiVehicles = await Vehicle.find({
        make: 'Audi',
        model: 'A4'
      });

      if (audiVehicles.length === 0) {
        console.log('❌ No Audi A4 found in database');
        return;
      }

      console.log(`📋 Found ${audiVehicles.length} Audi A4 vehicle(s)`);

      let successCount = 0;
      let errorCount = 0;

      for (const vehicle of audiVehicles) {
        try {
          console.log(`🎯 Processing vehicle: ${vehicle.name} (${vehicle.vehicleId})`);

          const images = this.getVehicleImages(vehicle);

          const updatedVehicle = await Vehicle.findByIdAndUpdate(
            vehicle._id,
            { $set: images },
            { new: true, runValidators: true }
          );

          if (updatedVehicle) {
            console.log(`✅ Successfully added images to ${vehicle.name}`);
            successCount++;
          } else {
            console.log(`❌ Failed to update ${vehicle.name}`);
            errorCount++;
          }
        } catch (error) {
          console.error(`❌ Error processing ${vehicle.name}:`, error.message);
          errorCount++;
        }
      }

      console.log(`\n📊 Summary for Audi A4:`);
      console.log(`✅ Successfully updated: ${successCount} vehicles`);
      console.log(`❌ Failed to update: ${errorCount} vehicles`);

    } catch (error) {
      console.error('❌ Error adding images to Audi A4:', error);
      throw error;
    }
  }

  async addImagesToBMW3SeriesJohannesburg() {
    try {
      console.log('🔍 Searching for BMW 3 Series in Johannesburg...');

      const bmwVehicles = await Vehicle.find({
        make: 'BMW',
        model: '3 Series',
        'currentLocation.city': 'Johannesburg'
      });

      if (bmwVehicles.length === 0) {
        console.log('❌ No BMW 3 Series found in Johannesburg');
        return;
      }

      console.log(`📋 Found ${bmwVehicles.length} BMW 3 Series vehicle(s) in Johannesburg`);

      const vehicle = bmwVehicles[0];
      console.log(`🎯 Processing vehicle: ${vehicle.name} (${vehicle.vehicleId})`);

      const images = this.getVehicleImages(vehicle);

      const updatedVehicle = await Vehicle.findByIdAndUpdate(
        vehicle._id,
        { $set: images },
        { new: true, runValidators: true }
      );

      if (updatedVehicle) {
        console.log('✅ Successfully added images to BMW 3 Series');
        console.log(`📸 Main image: ${updatedVehicle.imageUrl}`);
        console.log(`🖼️ Gallery images: ${updatedVehicle.imageGallery.length}`);
        console.log(`🏠 Exterior images: ${updatedVehicle.images.exterior.length}`);
        console.log(`🏨 Interior images: ${updatedVehicle.images.interior.length}`);
        console.log(`📄 Document images: ${updatedVehicle.images.documents.length}`);
      } else {
        console.log('❌ Failed to update vehicle with images');
      }

    } catch (error) {
      console.error('❌ Error adding images to BMW 3 Series:', error);
      throw error;
    }
  }

  async run() {
    try {
      await this.connect();

      const args = process.argv.slice(2);
      const command = args[0] || 'single';

      switch (command) {
        case 'all':
          const skipIfExists = !args.includes('--overwrite');
          await this.addImagesToAllVehicles({ skipIfExists });
          break;
        case 'audi':
          await this.addImagesToAudiA4();
          break;
        case 'bmw':
        default:
          await this.addImagesToBMW3SeriesJohannesburg();
          break;
      }

      console.log('🎉 Vehicle image addition completed successfully');
    } catch (error) {
      console.error('❌ Vehicle image addition failed:', error);
      process.exit(1);
    } finally {
      await this.disconnect();
    }
  }
}

// Usage examples:
// node addVehicleImages.js                    # Add images to BMW 3 Series (default test)
// node addVehicleImages.js bmw                # Add images to BMW 3 Series
// node addVehicleImages.js audi               # Add images to Audi A4 vehicles
// node addVehicleImages.js all                # Add images to all vehicles without images
// node addVehicleImages.js all --overwrite    # Add images to all vehicles (overwrite existing)

// Run if called directly
if (require.main === module) {
  const adder = new VehicleImageAdder();
  adder.run();
}

module.exports = VehicleImageAdder;
