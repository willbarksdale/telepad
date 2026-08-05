# TelePad MVP
Version: 0.1

## Objective

Build a desktop/web prototype that allows users to communicate with an AI using semantic keys instead of typing full sentences.

The prototype should answer one question:

Can semantic structure + abbreviated payload reconstruct user intent accurately?

---

# Layout

```
+-------------------------------------------+
| TelePad MVP                           |
+---------------------+---------------------+
|                     |                     |
|   Semantic Output   |   Payload Slots     |
|                     |                     |
|                     |                     |
+---------------------+---------------------+
|                                         |
|      1 2 3                              |
|      4 5 6                              |
|      7 8 9                              |
|        0                                |
+-----------------------------------------+
```

---

# Semantic Keys

| Key | Meaning |
|-----|---------|
| 1 | ASK |
| 2 | SELF |
| 3 | ACTION |
| 4 | STATE |
| 5 | TARGET |
| 6 | CONTEXT |
| 7 | GOAL |
| 8 | TIME |
| 9 | RELATION |
| 0 | SEND |

---

# Core Interaction

User presses a semantic key.
Slot appears immediately, cursor auto-focuses that slot.

Example flow:

Press 3 → [ACTION] [mk    ]
Press 5 → [ACTION] [mk    ]
          [TARGET] [scr   ]
Press 4 → [ACTION] [mk    ]
          [TARGET] [scr   ]
          [STATE ] [blk   ]

Each abbreviation is immediately bound to its semantic role.

---

# Payload Input

Each slot accepts:

- abbreviation
- partial word
- sketch (future)
- autocomplete (future)

Examples

```
ACTION  mk
TARGET  scr
STATE   blk
```

---

# AI Prompt Generation

Internally generate structured JSON.

Example

```json
{
  "semantic": [
    { "type": "ACTION", "value": "mk" },
    { "type": "TARGET", "value": "scr" },
    { "type": "STATE",  "value": "blk" }
  ]
}
```

Convert to prompt:

```
Expand these semantic slots into natural language.

ACTION = mk
TARGET = scr
STATE = blk

Return the intended sentence.
```

---

# Live Preview

While typing show:

```
Possible interpretation

Make the screen black.
```

Confidence: 95%

---

# Send

Press 0 or Enter.

Send reconstructed prompt to the LLM.

---

# History

Left panel

```
3 5 4
mk / scr / blk
↓
Make the screen black.
```

Store:
- semantic key sequence
- payload per slot
- AI output

---

# Rules

No grammar.
No punctuation.
No articles.
No complete words required.

The AI reconstructs English.

---

# Success Metric

The MVP succeeds if:

- Users can reconstruct intended prompts correctly.
- Payload averages only 2–4 letters per concept.
- Total interactions are fewer than typing naturally.
- Users learn the semantic keys in under 10 minutes.

---

# Interaction Model (Updated)

Press semantic key → slot appears immediately with cursor focused.
Abbreviation is bound to that slot's role on the spot.
This prevents ambiguity from a shared payload lane.

---

# Future Features (Not in MVP)

- Sketch payload
- Handwriting recognition
- Macro pad support
- USB numpad support
- Bluetooth numpad
- Mobile keyboard
- AI-learned abbreviations
- Context-aware autocomplete
- Personal semantic dictionary
