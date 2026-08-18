#!/usr/bin/env node
const { spawnSync } = require('child_process');
const path = require('path');

// Map targets to their setup/seed/validate scripts
const targets = {
  users: {
    setup: 'setupDatabase.js',
    seed: 'seedDatabase.js',
    validate: 'validateDatabase.js',
    seedArgs: []
  },
  analytics: {
    setup: 'setupAnalyticsDatabase.js',
    seed: 'seedAnalyticsDatabase.js',
    validate: 'validateAnalyticsDatabase.js',
    seedArgs: []
  },
  bookings: {
    setup: 'setupBookingsDatabase.js',
    seed: 'seedBookingsDatabase.js',
    validate: 'validateBookingsDatabase.js',
    seedArgs: []
  },
  drivers: {
    setup: 'setupDriversDatabase.js',
    seed: 'seedDriversDatabase.js',
    validate: 'validateDriversDatabase.js',
    seedArgs: []
  },
  location: {
    setup: 'setupLocationDatabase.js',
    seed: 'seedLocationDatabase.js',
    validate: 'validateLocationDatabase.js',
    seedArgs: []
  },
  notifications: {
    setup: 'setupNotificationsDatabase.js',
    seed: 'seedNotificationsDatabase.js',
    validate: 'validateNotificationsDatabase.js',
    seedArgs: []
  },
  payments: {
    setup: 'setupPaymentsDatabase.js',
    seed: 'seedPaymentsDatabase.js',
    validate: 'validatePaymentsDatabase.js',
    seedArgs: []
  },
  quotes: {
    setup: 'setupQuotesDatabase.js',
    seed: 'seedQuotesDatabase.js',
    validate: 'validateQuotesDatabase.js',
    seedArgs: []
  },
  specialfeatures: {
    setup: 'setupSpecialFeaturesDatabase.js',
    seed: 'seedSpecialFeaturesDatabase.js',
    validate: 'validateSpecialFeaturesDatabase.js',
    seedArgs: []
  },
  vehicles: {
    setup: 'setupVehiclesDatabase.js',
    seed: 'seedVehiclesDatabase.js',
    validate: 'validateVehiclesDatabase.js',
    seedArgs: []
  },
  support: {
    setup: 'setupSupportDatabase.js',
    seed: 'seedSupportDatabase.js',
    validate: 'validateSupportDatabase.js',
    seedArgs: []
  }
};

function runNode(script, args = []){
  const scriptPath = path.join(__dirname, script);
  const cmd = process.platform === 'win32' ? 'node.exe' : 'node';
  const res = spawnSync(cmd, [scriptPath, ...args], { stdio: 'inherit' });
  if (res.status !== 0) {
    throw new Error(`${script} failed with exit code ${res.status}`);
  }
}

function normalizeTarget(name){
  if (!name) return name;
  return String(name).toLowerCase().replace(/[-_\s]/g, '');
}

function usage(){
  console.log('Usage: node orchestrateDatabase.js --target <name>|--all [--skip-setup] [--skip-seed] [--skip-validate] [--setup-flags "--sample-data"] [--seed-flags "--clear-existing"]');
  console.log('Targets:', Object.keys(targets).join(', '));
}

function parseArgs(argv){
  const args = { skipSetup:false, skipSeed:false, skipValidate:false, setupFlags:[], seedFlags:[] };
  for (let i=2;i<argv.length;i++){
    const a = argv[i];
    if (a === '--target') { args.target = normalizeTarget(argv[++i]); continue; }
    if (a === '--all') { args.all = true; continue; }
    if (a === '--skip-setup') { args.skipSetup = true; continue; }
    if (a === '--skip-seed') { args.skipSeed = true; continue; }
    if (a === '--skip-validate') { args.skipValidate = true; continue; }
    if (a === '--setup-flags') { args.setupFlags = (argv[++i] || '').split(' ').filter(Boolean); continue; }
    if (a === '--seed-flags') { args.seedFlags = (argv[++i] || '').split(' ').filter(Boolean); continue; }
  }
  return args;
}

function resolveTargets(args){
  if (args.all) return Object.keys(targets);
  if (args.target) {
    if (!targets[args.target]) {
      console.error(`Unknown target: ${args.target}`);
      usage();
      process.exit(1);
    }
    return [args.target];
  }
  usage();
  process.exit(1);
}

function main(){
  const args = parseArgs(process.argv);
  const runList = resolveTargets(args);

  for (const name of runList){
    const t = targets[name];
    console.log(`\n===== ${name.toUpperCase()} =====`);

    if (!args.skipSetup) {
      const setupArgs = args.setupFlags.length ? args.setupFlags : ['--sample-data'];
      console.log(`\n▶️  SETUP: ${t.setup} ${setupArgs.join(' ')}`);
      runNode(t.setup, setupArgs);
    }

    if (!args.skipSeed && t.seed) {
      const seedArgs = args.seedFlags.length ? args.seedFlags : [];
      console.log(`\n▶️  SEED: ${t.seed} ${seedArgs.join(' ')}`);
      runNode(t.seed, seedArgs);
    }

    if (!args.skipValidate) {
      console.log(`\n▶️  VALIDATE: ${t.validate}`);
      runNode(t.validate, []);
    }

    console.log(`\n✅ Completed: ${name}`);
  }

  console.log('\n🎉 Orchestration completed successfully');
}

if (require.main === module){
  try { main(); process.exit(0); } catch (e) { console.error(e.message || e); process.exit(1); }
}

module.exports = { targets };
