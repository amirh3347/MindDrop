# Backup format

MindDrop backups are UTF-8 JSON files. The same format is used for the app's own
storage (`tasks.json` in the app's private directory), so a backup is an exact copy of
your data.

```json
{
  "app": "MindDrop",
  "format": 1,
  "exportedAt": "2026-10-27T14:30:00.000",
  "count": 1,
  "tasks": [
    {
      "id": "m3k9x1a0b2c3d4e",
      "title": "Buy milk",
      "note": "Lactose-free",
      "priority": "medium",
      "tags": ["home"],
      "subtasks": [
        { "id": "m3k9x1b9z8y7x6w", "title": "Check fridge", "done": true }
      ],
      "done": false,
      "pinned": false,
      "createdAt": "2026-10-27T09:12:44.120",
      "updatedAt": "2026-10-27T09:15:02.871",
      "dueAt": "2026-10-28T18:00:00.000",
      "hasDueTime": true,
      "remindAt": "2026-10-28T18:00:00.000"
    }
  ]
}
```

## Fields

| Field | Type | Notes |
|---|---|---|
| `app` | string | Always `"MindDrop"`. Files with another value are rejected. |
| `format` | int | Layout version. Files with a newer format than the app supports are rejected. |
| `exportedAt` | ISO-8601 | Informational. |
| `count` | int | Informational. |
| `tasks[].id` | string | Unique. Used to match tasks when merging. |
| `tasks[].title` | string | Required; tasks with an empty title are skipped. |
| `tasks[].note` | string | Optional. |
| `tasks[].priority` | `none` \| `low` \| `medium` \| `high` | Defaults to `none`. |
| `tasks[].tags` | string[] | Without the `#`. |
| `tasks[].subtasks` | `{id, title, done}[]` | Optional. |
| `tasks[].done` / `pinned` | bool | |
| `tasks[].createdAt` / `updatedAt` / `completedAt` | ISO-8601 | Local time. `updatedAt` decides which copy wins when merging. |
| `tasks[].dueAt` | ISO-8601 | Due date; only the date part matters unless `hasDueTime` is `true`. |
| `tasks[].remindAt` | ISO-8601 | When to show a reminder. |

Unknown fields are ignored and missing optional fields get defaults, so older and newer
app versions can read each other's backups as long as `format` is supported. A bare JSON
array of tasks is accepted too.

## Import modes

- **Merge** — tasks with new ids are added; for ids that exist on both sides the copy with
  the newer `updatedAt` wins. Nothing is deleted.
- **Replace** — all current tasks are removed and the backup's tasks are loaded.

Reminders are re-scheduled after every import.
