// Create Linear tickets for Cursed Museum from DESIGN.md §13 backlog.
// Usage:
//   node scripts/create_linear_tickets.mjs            # creates all tickets
//   node scripts/create_linear_tickets.mjs --dry-run  # parse only, no API calls
//   node scripts/create_linear_tickets.mjs --first 5  # only first N tickets
// Requires: process.env.LINEAR_API_KEY set.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DESIGN_PATH = path.join(__dirname, "..", "DESIGN.md");

// Linear IDs (looked up earlier via API)
const TEAM_ID = "5db99655-862b-4f08-b7ae-ba7a55294e71"; // MEM
const PROJECT_ID = "e981b635-6059-438c-9acd-dee8b8adc779"; // cursed-museum
const STATE_TODO = "debc6ad8-32b4-4eee-89c3-4ddf1bca07ec"; // Todo

const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const firstIdx = args.indexOf("--first");
const firstN = firstIdx >= 0 ? Number(args[firstIdx + 1]) : null;
const skipIdx = args.indexOf("--skip");
const skipN = skipIdx >= 0 ? Number(args[skipIdx + 1]) : 0;

const apiKey = process.env.LINEAR_API_KEY;
if (!apiKey && !dryRun) {
  console.error("LINEAR_API_KEY env var not set. In PowerShell, run a new shell after setting it user-level.");
  process.exit(1);
}

// Parse the backlog
const md = fs.readFileSync(DESIGN_PATH, "utf-8");
const re = /^- \*\*CRSD-([A-Z0-9-]+)\*\* \[(.+?)\]\s+(.+)$/gm;
const tickets = [];
let m;
while ((m = re.exec(md)) !== null) {
  const id = `CRSD-${m[1]}`;
  const deps = m[2];
  const title = m[3].replace(/\.$/, "");
  const shortTitle = title.length > 90 ? title.slice(0, 87) + "..." : title;
  tickets.push({ id, deps, title, shortTitle });
}

console.log(`Parsed ${tickets.length} tickets from DESIGN.md`);

if (dryRun) {
  console.log("\n=== DRY RUN — first 5 ===");
  tickets.slice(0, 5).forEach((t) => {
    console.log(`  ${t.id} [${t.deps}]`);
    console.log(`    ${t.shortTitle}`);
  });
  process.exit(0);
}

const afterSkip = tickets.slice(skipN);
const slice = firstN ? afterSkip.slice(0, firstN) : afterSkip;
console.log(`Creating ${slice.length} tickets in Linear (skipped first ${skipN})...\n`);

async function gql(query, variables) {
  const res = await fetch("https://api.linear.app/graphql", {
    method: "POST",
    headers: { Authorization: apiKey, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await res.json();
  if (json.errors) {
    throw new Error(JSON.stringify(json.errors));
  }
  return json.data;
}

const MUTATION = `
mutation IssueCreate($input: IssueCreateInput!) {
  issueCreate(input: $input) {
    success
    issue { id identifier title }
  }
}`;

const idMap = {};
let created = 0;
let failed = 0;

for (let i = 0; i < slice.length; i++) {
  const t = slice[i];
  const titleFull = `${t.id} - ${t.shortTitle}`;
  const description = `## Description

${t.title}

## Dependencies

${t.deps}

## Source

See \`DESIGN.md\` §13 backlog (full task description in this section). Refer to other GDD sections cited in the description (§5, §6, §8, etc.) for spec details.

## Acceptance criteria

- Implementation matches the relevant DESIGN.md spec section.
- Tests added under \`res://tests/\` where applicable.
- \`godot --headless --script addons/gdUnit4/bin/gdUnit4.gd --add-only res://tests\` passes locally.
- PR opened with branch \`${t.id.toLowerCase()}-<short-slug>\`, label \`symphony\`, links this ticket.
`;

  // CRSD-001 = Urgent (1) so Symphony picks it first; others = Normal (3)
  const priority = t.id === "CRSD-001" ? 1 : 3;

  const input = {
    teamId: TEAM_ID,
    projectId: PROJECT_ID,
    stateId: STATE_TODO,
    title: titleFull,
    description,
    priority,
  };

  try {
    const data = await gql(MUTATION, { input });
    if (data.issueCreate.success) {
      const { id, identifier } = data.issueCreate.issue;
      idMap[t.id] = id;
      created++;
      console.log(`[${String(created).padStart(3)}/${slice.length}] OK  ${t.id.padEnd(12)} -> ${identifier}  ${t.shortTitle}`);
    } else {
      failed++;
      console.log(`[FAIL] ${t.id}: no success flag`);
    }
  } catch (err) {
    failed++;
    console.log(`[FAIL] ${t.id}: ${err.message}`);
  }

  // Light rate limit
  await new Promise((r) => setTimeout(r, 200));
}

console.log("\n===================================");
console.log(`Created: ${created} / ${slice.length}`);
console.log(`Failed:  ${failed}`);
console.log("===================================");

const mapPath = path.join(__dirname, "linear_ticket_id_map.json");
fs.writeFileSync(mapPath, JSON.stringify(idMap, null, 2), "utf-8");
console.log(`ID map saved to ${mapPath}`);
