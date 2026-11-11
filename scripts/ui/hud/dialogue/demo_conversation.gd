class_name DemoConversation
extends RefCounted
## Data percakapan demo. Ganti dengan dialog game yang asli.

const LINES := [
	{"who": "npc", "text": "You dare enter my sanctum, Veilwalker?"},
	{"who": "mc", "text": "I have come for the Veil fragment."},
	{"who": "npc", "text": "Then answer me this: are you ready to pay the price?",
		"choices": [
			{"text": "Yes, I am ready.", "goto": 3},
			{"text": "No, not yet.", "goto": 5},
		]},
	{"who": "npc", "text": "Then take it, and may the Veil forgive you."},
	{"who": "mc", "text": "I will carry it with honor.", "end": true},
	{"who": "npc", "text": "Then leave, and return when you are ready.", "end": true},
]
