# Cape Town Vehicles Seeding Script

This script adds Cape Town vehicles to the database with different vehicles across all required categories.

## Categories Included

- **Luxury Sedans** (category: `sedan`) - 3 vehicles
  - Mercedes-Benz S-Class
  - BMW 7 Series
  - Audi A8

- **SUVs** (category: `suv`) - 3 vehicles
  - Range Rover Sport
  - Audi Q7
  - BMW X5

- **Luxury Vans** (category: `van`) - 2 vehicles
  - Mercedes-Benz V-Class
  - Toyota Alphard

- **Sports Cars** (category: `luxury`) - 2 vehicles
  - Porsche 911
  - Audi R8

- **Hybrids** (category: `hybrid`) - 3 vehicles
  - Toyota Prius Hybrid
  - Lexus ES Hybrid
  - BMW 530e Hybrid

**Total: 13 vehicles**

## Usage

### Basic Usage (Add vehicles without clearing existing)

```bash
cd Swiftlyft_backend
node scripts/addCapeTownVehicles.js
```

### Clear Existing Cape Town Vehicles First

If you want to remove all existing Cape Town vehicles before adding new ones:

```bash
cd Swiftlyft_backend
node scripts/addCapeTownVehicles.js --clear-existing
```

## Prerequisites

1. Make sure your `.env` file has the correct `MONGODB_URI` set
2. Ensure MongoDB is running and accessible
3. Node.js and npm dependencies should be installed

## What the Script Does

1. Connects to MongoDB using the connection string from `.env`
2. Optionally clears existing Cape Town vehicles (if `--clear-existing` flag is used)
3. Creates 13 vehicles across all required categories
4. Sets all vehicles to `available` status
5. Assigns Cape Town coordinates and location data
6. Configures pricing, features, and specifications for each vehicle
7. Prints a summary showing counts by category

## Output

The script will print:
- Connection status
- Number of vehicles created
- Summary by category
- Total Cape Town vehicles in database

Example output:
```
✅ Connected to MongoDB
📊 Database: swiftlyft
🚗 Creating 13 Cape Town vehicles...
✅ Successfully created 13 vehicles

📊 Summary by category:
   Luxury Sedans (sedan): 3
   SUVs (suv): 3
   Luxury Vans (van): 2
   Sports Cars (luxury): 2
   Hybrids (hybrid): 3

🎉 Total Cape Town vehicles in database: 13
✅ Cape Town vehicle seeding completed successfully
```

## Notes

- Each vehicle is assigned a unique `vehicleId` with a timestamp-based suffix
- License plates are randomly generated with "CPT" prefix
- All vehicles are set to `available` status with working hours 06:00-23:00
- Vehicles are located in Cape Town City Centre with slight coordinate variations
- The script handles driver ID assignment automatically (uses existing driver if available)

