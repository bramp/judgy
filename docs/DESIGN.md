# Design

This document records the architecture and significant design decisions for Judgy's online multiplayer system.

## Overview

Judgy is an Apples-to-Apples style card game. The online multiplayer system allows players to create private game rooms, share join codes, and play in real-time over Firebase Firestore.

## Service Architecture

```
┌──────────────────┐     ┌────────────────────┐
│ MatchmakingService│     │  OnlineGameEngine   │
│                  │     │                    │
│ • createRoom()   │     │ • listenToRoom()   │
│ • joinByCode()   │     │ • startGame()      │
│                  │     │ • playCard()       │
│                  │     │ • selectWinner()   │
│                  │     │ • nextRound()      │
│                  │     │ • leaveRoom()      │
└──────┬───────────┘     └──────┬─────────────┘
       │                        │
       └────────┬───────────────┘
                │
       ┌────────▼────────┐
       │   Firestore      │
       │   /rooms/{id}    │
       └─────────────────┘
```

- **MatchmakingService**: Creates and joins rooms. Stateless utility.
- **OnlineGameEngine**: Manages in-room gameplay. Extends `ChangeNotifier` for UI binding. Subscribes to Firestore snapshots for real-time sync.

## Firestore Schema

### `/rooms/{roomId}` (single document per game)

```
{
  id: string,                    // Room UUID
  joinCode: string,              // 6-char alphanumeric code (A-Z, 0-9, no confusing chars)
  hostId: string,                // Host player's Firebase UID
  players: [                     // Array of player objects
    {
      id: string,                // Firebase UID
      displayName: string,
      isBot: bool,
      botPersonality: object?,
      score: int,
      hand: [CardModel...]       // Player's current cards
    }
  ],
  status: string,                // lobby|dealing|playersPlaying|judging|scoring|finished
  currentRound: {
    id: string,
    judgeId: string,
    currentAdjective: CardModel,
    playedCards: [PlayedCard...],
    winningPlayerId: string?
  },
  roundNumber: int,
  createdAt: int                 // Milliseconds since epoch
}
```

## Game Flow

### State Machine

```
lobby ──[host starts]──> playersPlaying ──[all played]──> judging
                              ▲                               │
                              │                    [judge picks winner]
                              │                               ▼
                         [next round]◄────────────────── scoring
                                                              │
                                                    [score limit reached]
                                                              ▼
                                                          finished
```

### User Journey

#### Creating a Game
1. Player taps "Create Game" on home screen
2. If not authenticated → auto sign-in anonymously
3. `MatchmakingService.createPrivateRoom()` creates room in Firestore
4. Navigate to online game screen → shows lobby view
5. Share the 6-character join code with friends

#### Joining a Game
1. Player taps "Join Game" on home screen
2. Navigate to join game screen
3. Enter 6-character code
4. If not authenticated → auto sign-in anonymously
5. `MatchmakingService.joinRoomByCode()` adds player to room
6. Navigate to online game screen → shows lobby view

#### Playing the Game
1. Host taps "Start Game" (requires 3+ players)
2. Host deals 7 noun cards to each player
3. Round begins: adjective revealed, judge rotates round-robin
4. Non-judge players select a noun card from their hand
5. When all players have played → cards shuffled and revealed
6. Judge selects winning card
7. Scores updated → "Next Round" button (host only)
8. Hands replenished, next judge selected, repeat

## Validation Rules

### Joining a Room
- Room must exist (found by join code query)
- Room must be in `lobby` state (game not started)
- Room must have fewer than 8 players
- If player already in room → returns existing room ID

### Starting a Game
- Only the host can start
- Room must be in `lobby` state
- At least 3 players required

### Playing Cards
- Room must be in `playersPlaying` state
- Player must not be the judge
- Player must not have already played this round
- Card must be in the player's hand

### Selecting Winner
- Room must be in `judging` state
- Only the current round's judge can select

### Advancing Rounds
- Only the host can advance
- Room must be in `scoring` state

---

## Design Decisions

### 1. Client-Authoritative Host Model

**Decision:** The host client (the player who created the room) is authoritative for game state mutations like dealing cards, starting rounds, and advancing the game.

**Alternatives considered:**
- **Cloud Functions (server-authoritative):** A Cloud Function could handle all state transitions server-side, triggered by Firestore writes or callable functions. This is the most secure approach because no client can cheat.
- **Fully peer-to-peer:** Every client writes its own state changes and they converge. This is hard to coordinate and has many race conditions.

**Why host-authoritative:**
- **Simplicity:** No Cloud Functions infrastructure to deploy, version, or debug. All logic lives in the Dart codebase.
- **Speed of iteration:** Changes to game logic don't require deploying server-side code.
- **Good enough for MVP:** This is a cooperative party game — the host is a trusted friend. There's no competitive matchmaking where cheating has high stakes.
- **Easy migration path:** The host-side logic in `OnlineGameEngine` (dealing, round advancement) can later be extracted into Cloud Functions with minimal refactoring, since it already operates on `GameRoom` JSON.

**Risks / tradeoffs:**
- A malicious or modified host client could deal unfair hands or manipulate game state.
- If the host disconnects mid-deal, the game can stall. (Mitigated by host transfer on leave.)
- No server-side validation of state transitions — any authenticated client could technically write arbitrary data to their room document.

**When to revisit:** If we add public matchmaking with strangers, or if cheating becomes a concern, we should move dealing and state transitions to Cloud Functions.

### 2. Single Firestore Document Per Room

**Decision:** All game state — room metadata, player list, hands, current round, played cards — is stored in one Firestore document at `/rooms/{roomId}`.

**Alternatives considered:**
- **Subcollections:** `/rooms/{roomId}/players/{playerId}` for hands, `/rooms/{roomId}/rounds/{roundId}` for round history. This enables fine-grained security rules (players can only read their own hand).
- **Hybrid:** Room metadata in the document, sensitive data (hands) in subcollections.

**Why a single document:**
- **Atomic reads:** One `snapshots()` listener gives the client the entire game state. No need to coordinate multiple listeners or handle partial updates.
- **Atomic writes:** Updating round state + player scores + game status happens in one `update()` call, avoiding inconsistent intermediate states.
- **Simplicity:** Fewer Firestore reads/writes, simpler code, easier to reason about.
- **Low player count:** With 3-8 players and 7 cards each, the document stays well under Firestore's 1 MB document size limit (typical room is ~5-10 KB).

**Risks / tradeoffs:**
- **No hand privacy:** All clients can read the full document, including other players' hands. A player inspecting the Firestore snapshot (via dev tools) could see opponents' cards.
- **Write contention:** Multiple players submitting cards simultaneously could cause write conflicts. In practice this is rare because players submit at different times and Firestore's last-write-wins is acceptable for card plays (each play adds to a list).
- **No round history:** Only the current round is stored. Past rounds are lost when overwritten.

**When to revisit:** If hand privacy matters (competitive play), move hands to subcollections with security rules restricting reads to the owning player. If round history is needed (for stats or replays), use a `rounds` subcollection.

### 3. Join Codes Over Room IDs

**Decision:** Players join rooms by entering a short 6-character alphanumeric code (e.g., `HK7M3V`) rather than sharing a Firestore document ID or URL.

**Design:**
- 6 characters from `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (29 chars, excludes `0/O`, `1/I/L` to avoid confusion when read aloud or typed).
- Generated with `Random.secure()`.
- Queried via `where('joinCode', isEqualTo: code)`.

**Why:**
- **Human-friendly:** Easy to read aloud, type on a phone, or share in a text message.
- **Sufficient entropy:** 29^6 = ~594 million possible codes. With rooms expiring after use, collision probability is negligible.
- **No deep links needed:** Works without platform-specific URL handling or Firebase Dynamic Links.

**Risks / tradeoffs:**
- Brute-force guessing is theoretically possible but impractical (594M codes, Firestore rate limits).
- No expiry mechanism yet — old room codes could be re-found if rooms aren't cleaned up.

### 4. Anonymous Auth as Default

**Decision:** When a player creates or joins an online game without being signed in, we auto-sign them in anonymously via Firebase Auth.

**Why:**
- **Zero friction:** Players can jump into a game immediately without creating an account.
- **Upgradeable:** Firebase supports linking anonymous accounts to permanent providers (Google, Apple) later.
- **Required for Firestore rules:** Our security rules require `request.auth != null`, so even anonymous users need an auth token.

**Risks / tradeoffs:**
- Anonymous accounts have no identity persistence across app reinstalls or device changes.
- Display names default to generic values ("Player") since there's no profile.

---

## Future Improvements

- **Cloud Functions** for server-side card dealing and state validation
- **Firestore subcollections** for private player hands
- **Firestore transactions** for concurrent card plays
- **Public matchmaking queue** for random pairing
- **Spectator mode** for watching games in progress
- **Reconnection handling** for dropped connections
- **Room expiry** for cleaning up abandoned games
- **Bot support** in online games (host runs bot logic)
