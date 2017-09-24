# Firebase Settings

## Database Structure

```json
{
  "teams": {
    "team_id_foo": {
      "name": "Team Foo"
    },
    "team_id_bar": {
      "name": "Barbarians"
    },
    "team_id_baz": {
      "name": "In my house"
    }
  },

  "team_members": {
    "team_id_foo": {
      "user_id_x": "Tom",
      "user_id_y": "Jessy"
    },
    "team_id_bar": {
      "user_id_z": "Mark"
    },
    "team_id_baz": {
      "user_id_z": "Mark"
    }
  },

  "member_teams": {
    "user_id_x": {
      "team_id_foo": "Team Foo"
    },
    "user_id_y": {
      "team_id_foo": "Team Foo"
    },
    "user_id_z": {
      "team_id_bar": "Barbarians",
      "team_id_baz": "In my house"
    }
  },

  "items": {
    "team_id_foo": {
      "item_id_a": {
        "name": "Tissue",
        "insufficient": false,
        "last_change": 1504795120095
      },
      "item_id_b": {
        "name": "Cleanser",
        "insufficient": false,
        "last_change": 1504781342145
      },
      "item_id_c": {
        "name": "Milk",
        "insufficient": true,
        "last_change": 1504791327821
      }

    },
    "team_id_bar": {

    }
  }

}
```

## Rules

```json
```
