/**
 * Fix TensorFlow.js Node Build for Electron
 *
 * After electron-rebuild, the tfjs-node native binding and shared libraries
 * may not be in the locations that tfjs-node expects at runtime inside an
 * Electron app (especially after asar packing). This script copies/renames
 * the required files so that both development and packaged builds work.
 *
 * Usage: node scripts/build/fix-tfjs-node-build.js
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..', '..');
const TFJS_NODE_DIR = path.join(PROJECT_ROOT, 'node_modules', '@tensorflow', 'tfjs-node');

function log(msg) {
  console.log(`[fix-tfjs-node-build] ${msg}`);
}

function warn(msg) {
  console.warn(`[fix-tfjs-node-build] WARNING: ${msg}`);
}

/**
 * Ensure the native binding file is accessible at the path tfjs-node expects.
 * After electron-rebuild the binding may land in a build/Release subdir
 * but the JS loader may look for it at lib/napi-vN/tfjs_binding.node.
 */
function fixBindingPath() {
  const libDir = path.join(TFJS_NODE_DIR, 'lib');
  const buildRelease = path.join(TFJS_NODE_DIR, 'build', 'Release');

  // Find the binding in build/Release
  const bindingName = 'tfjs_binding.node';
  const releaseBinding = path.join(buildRelease, bindingName);

  if (!fs.existsSync(releaseBinding)) {
    // Try napi dirs
    const napiDirs = fs.existsSync(libDir)
      ? fs.readdirSync(libDir).filter(d => d.startsWith('napi-v'))
      : [];

    for (const napiDir of napiDirs) {
      const napiBinding = path.join(libDir, napiDir, bindingName);
      if (fs.existsSync(napiBinding)) {
        log(`Binding already present at ${napiBinding}`);
        return;
      }
    }

    warn(`No tfjs_binding.node found in build/Release or lib/napi-v*. Skipping binding fix.`);
    return;
  }

  // Copy to lib/napi-v8 (common Electron napi version) if not already there
  const targetNapiDir = path.join(libDir, 'napi-v8');
  const targetBinding = path.join(targetNapiDir, bindingName);

  if (!fs.existsSync(targetBinding)) {
    fs.mkdirSync(targetNapiDir, { recursive: true });
    fs.copyFileSync(releaseBinding, targetBinding);
    log(`Copied ${bindingName} to ${targetNapiDir}`);
  } else {
    log(`Binding already present at ${targetBinding}`);
  }
}

/**
 * On Windows, TensorFlow.js needs tensorflow.dll alongside the binding.
 * The deps/ folder is excluded from asar, so we also copy it to lib/.
 */
function fixTensorFlowDll() {
  if (process.platform !== 'win32') {
    log('Not on Windows - skipping DLL fix');
    return;
  }

  const depsDir = path.join(TFJS_NODE_DIR, 'deps');
  const dllName = 'tensorflow.dll';
  const srcDll = path.join(depsDir, dllName);

  if (!fs.existsSync(srcDll)) {
    const libDir = path.join(TFJS_NODE_DIR, 'deps', 'lib');
    const altDll = path.join(libDir, dllName);
    if (fs.existsSync(altDll)) {
      const targetDir = path.join(TFJS_NODE_DIR, 'lib');
      const targetDll = path.join(targetDir, dllName);
      if (!fs.existsSync(targetDll)) {
        fs.copyFileSync(altDll, targetDll);
        log(`Copied ${dllName} from deps/lib to lib/`);
      }
    } else {
      warn(`${dllName} not found in deps/ - the TensorFlow shared library may need to be downloaded`);
    }
    return;
  }

  const targetDir = path.join(TFJS_NODE_DIR, 'lib');
  const targetDll = path.join(targetDir, dllName);

  if (!fs.existsSync(targetDll)) {
    fs.copyFileSync(srcDll, targetDll);
    log(`Copied ${dllName} to lib/`);
  } else {
    log(`${dllName} already in lib/`);
  }
}

function main() {
  log('Fixing TensorFlow.js Node build for Electron...');

  if (!fs.existsSync(TFJS_NODE_DIR)) {
    warn('@tensorflow/tfjs-node is not installed. Skipping fixes.');
    return;
  }

  try {
    fixBindingPath();
    fixTensorFlowDll();
    log('Done.');
  } catch (err) {
    console.error(`[fix-tfjs-node-build] ERROR: ${err.message}`);
    console.error(err.stack);
    process.exit(1);
  }
}

main();
