# Spec Delta

## ADDED Requirements

### Requirement: Bridges are drawn with railings
Every drawn bridge deck SHALL have a railing 1.1 m high along each of its two edges, as long as
the deck.

#### Scenario: Two railings per deck
- **WHEN** a chunk owning M bridges is loaded
- **THEN** exactly 2 × M railings are drawn, each as long as its deck and 1.1 m high
