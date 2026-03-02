/**
 * Generate Mock Data
 *
 * Creates mock data files for testing the application without a real
 * Dota 2 database or live scraping. Delegates to the mock data generators
 * in src/test/.
 *
 * Usage:
 *   node scripts/generate-mock-data.js [output-dir]
 *
 * Output:
 *   Creates JSON files in the specified directory (default: ./mock-data/)
 */

const fs = require('fs');
const path = require('path');

// Import mock generators
const generators = (() => {
  try {
    return require('../src/test/mockDataGenerators');
  } catch (err) {
    console.error('Error: Could not load mock data generators from src/test/mockDataGenerators.js');
    console.error(err.message);
    process.exit(1);
  }
})();

const { generateAbilities, generateHero, generateAbilityPair, generateLayoutCoordinates, SAMPLE_HEROES } = generators;

function main() {
  const outputDir = process.argv[2] || path.join(__dirname, '..', 'mock-data');

  console.log(`Generating mock data in: ${outputDir}`);
  fs.mkdirSync(outputDir, { recursive: true });

  // Generate abilities
  const abilities = generateAbilities ? generateAbilities(100) : [];
  fs.writeFileSync(
    path.join(outputDir, 'abilities.json'),
    JSON.stringify(abilities, null, 2)
  );
  console.log(`  abilities.json: ${abilities.length} abilities`);

  // Generate heroes
  const heroes = SAMPLE_HEROES
    ? SAMPLE_HEROES.slice(0, 25).map((name, i) => generateHero ? generateHero({ name, id: i + 1 }) : { name, id: i + 1 })
    : [];
  fs.writeFileSync(
    path.join(outputDir, 'heroes.json'),
    JSON.stringify(heroes, null, 2)
  );
  console.log(`  heroes.json: ${heroes.length} heroes`);

  // Generate ability pairs
  const pairs = [];
  if (generateAbilityPair) {
    for (let i = 0; i < 50; i++) {
      pairs.push(generateAbilityPair());
    }
  }
  fs.writeFileSync(
    path.join(outputDir, 'ability-pairs.json'),
    JSON.stringify(pairs, null, 2)
  );
  console.log(`  ability-pairs.json: ${pairs.length} pairs`);

  // Generate layout coordinates
  const resolutions = ['1920x1080', '2560x1440', '1440x900', '1366x768'];
  const layoutCoords = {};
  if (generateLayoutCoordinates) {
    for (const res of resolutions) {
      layoutCoords[res] = generateLayoutCoordinates(res);
    }
  } else {
    for (const res of resolutions) {
      const [w, h] = res.split('x').map(Number);
      layoutCoords[res] = {
        ultimate_slots_coords: Array.from({ length: 12 }, (_, i) => ({
          x: Math.round(50 + (i % 6) * (w / 8)),
          y: Math.round(h * 0.15),
          width: Math.round(w * 0.04),
          height: Math.round(w * 0.04),
          hero_order: Math.floor(i / 6),
          is_ultimate: true
        })),
        standard_slots_coords: Array.from({ length: 36 }, (_, i) => ({
          x: Math.round(50 + (i % 6) * (w / 8)),
          y: Math.round(h * 0.25 + Math.floor(i / 6) * (h * 0.1)),
          width: Math.round(w * 0.04),
          height: Math.round(w * 0.04),
          hero_order: Math.floor(i / 3) % 12,
          is_ultimate: false
        }))
      };
    }
  }
  fs.writeFileSync(
    path.join(outputDir, 'layout-coordinates.json'),
    JSON.stringify(layoutCoords, null, 2)
  );
  console.log(`  layout-coordinates.json: ${resolutions.length} resolutions`);

  // Generate test scenarios
  const scenarios = {
    initialScan: {
      description: 'First scan after entering Ability Draft',
      isInitialScan: true,
      expectedAbilities: abilities.slice(0, 48).map(a => a.name || a.ability_name || ''),
      expectedHeroes: heroes.slice(0, 12).map(h => h.name || h.hero_name || '')
    },
    subsequentScan: {
      description: 'Scan after some abilities have been picked',
      isInitialScan: false,
      expectedAbilities: abilities.slice(0, 40).map(a => a.name || a.ability_name || ''),
      pickedAbilities: abilities.slice(40, 48).map(a => a.name || a.ability_name || '')
    }
  };
  fs.writeFileSync(
    path.join(outputDir, 'test-scenarios.json'),
    JSON.stringify(scenarios, null, 2)
  );
  console.log(`  test-scenarios.json: ${Object.keys(scenarios).length} scenarios`);

  console.log('\nMock data generation complete.');
}

main();
