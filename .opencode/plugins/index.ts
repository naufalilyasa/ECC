/**
 * ECC Plugins for OpenCode
 *
 * This module exports all ECC plugins for OpenCode integration.
 * Plugins provide hook-based automation that mirrors Claude Code's hook system
 * while taking advantage of OpenCode's more sophisticated 20+ event types.
 *
 * Note: this plugin targets the OpenCode v1 Plugin API. OpenCode v2 replaced
 * hooks with the Plugin Events API, so `"plugin": []` in opencode.json keeps it
 * unloaded at runtime; the module is retained for the v1 contract and build.
 */

export { ECCHooksPlugin, default } from "./ecc-hooks.ts"

// Re-export for named imports
export * from "./ecc-hooks.ts"
