// Move all MEM tickets to Backlog except MEM-5 (which stays Todo).
// Lets Symphony only dispatch CRSD-001 first; once that's Done, we promote the unblocked deps.
//
// Usage: node scripts/park_tickets.mjs

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const apiKey = process.env.LINEAR_API_KEY;
if (!apiKey) {
  console.error("LINEAR_API_KEY not set");
  process.exit(1);
}

const TEAM_ID = "5db99655-862b-4f08-b7ae-ba7a55294e71";
const STATE_TODO = "debc6ad8-32b4-4eee-89c3-4ddf1bca07ec";
const STATE_BACKLOG = "876be66e-2518-4c89-9fa0-56c2e16d038a";

// Don't touch these — MEM-5 is the only ticket we want active right now.
const KEEP_ACTIVE = new Set(["MEM-5"]);

async function gql(query, variables = {}) {
  const res = await fetch("https://api.linear.app/graphql", {
    method: "POST",
    headers: { Authorization: apiKey, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await res.json();
  if (json.errors) throw new Error(JSON.stringify(json.errors));
  return json.data;
}

// Fetch ALL non-Done MEM tickets
const data = await gql(`{
  team(id: "${TEAM_ID}") {
    issues(first: 250, filter: {state: {name: {nin: ["Done", "Canceled", "Duplicate"]}}}) {
      nodes { id identifier title state { name } }
    }
  }
}`);

const tickets = data.team.issues.nodes;
console.log(`Found ${tickets.length} non-terminal MEM tickets\n`);

let parked = 0;
let restored = 0;
let kept = 0;

for (const t of tickets) {
  const targetState = KEEP_ACTIVE.has(t.identifier) ? STATE_TODO : STATE_BACKLOG;
  const targetName = KEEP_ACTIVE.has(t.identifier) ? "Todo" : "Backlog";

  if (t.state.name === targetName) {
    console.log(`SKIP ${t.identifier} already ${targetName}`);
    kept++;
    continue;
  }

  try {
    await gql(
      `mutation($id:String!,$state:String!){issueUpdate(id:$id,input:{stateId:$state}){success}}`,
      { id: t.id, state: targetState }
    );
    if (KEEP_ACTIVE.has(t.identifier)) {
      console.log(`OK   ${t.identifier} -> ${targetName} (was ${t.state.name})`);
      restored++;
    } else {
      console.log(`PARK ${t.identifier} -> Backlog (was ${t.state.name})`);
      parked++;
    }
  } catch (err) {
    console.log(`FAIL ${t.identifier}: ${err.message}`);
  }
  await new Promise((r) => setTimeout(r, 100));
}

console.log(`\n${parked} parked to Backlog, ${restored} restored to Todo, ${kept} unchanged.`);
