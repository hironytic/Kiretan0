# Firebase Settings

## Database Structure (Cloud Firestore)

- `[C]` … Collection
- `[D]` … Document

```json
{
  "[C] team": {
    "[D] team_id_foo": {
      "name": "Team Foo",
      "[C] member": {
        "[D] user_id_x": {
          "name": "Tom"
        },
        "[D] user_id_y": {
          "name": "Jessy"
        }
      },
      "[C] item": {
        "[D] item_id_a": {
          "name": "Tissue",
          "insufficient": false,
          "last_change": 1504795120095
        },
        "[D] item_id_b": {
          "name": "Cleanser",
          "insufficient": false,
          "last_change": 1504781342145
        },
        "[D] item_id_c": {
          "name": "Milk",
          "insufficient": true,
          "last_change": 1504791327821
        }        
      }
    },
    "[D] team_id_bar": {
      "name": "Barbarians",
      "[C] member": {
        "[D] user_id_z": {
          "name": "Mark"
        }
      }
    },
    "[D] team_id_baz": {
      "name": "In my house",
      "[C] member": {
        "[D] user_id_z": {
          "name": "Mark"
        }
      }
    }
  },
  "[C] member_team": {
    "[D] user_id_x": {
      "team_id_foo": true
    },
    "[D] user_id_y": {
      "team_id_foo": true
    },
    "[D] user_id_z": {
      "team_id_bar": true,
      "team_id_baz": true
    }
  }
}
```
