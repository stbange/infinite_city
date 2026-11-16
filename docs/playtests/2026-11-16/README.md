# Autoplay sessions, 2026-11-16

Ten sessions of 60–120 minutes of real play time, run with `tools/autoplay.gd`: a scripted courier
plays through the game's own rules (courier board and rivals, nav routes walked at 4.5 m/s,
doorsteps, gang tolls and Authority checkpoints on crossed bridges, the main plot and a side arc,
rent, licences, the daily live simulation). It counts reading time for scenes, doors and
encounters, and sleeps at home from 23:30 to 07:00.

Simplifications: no steering a body (the route is walked as a whole), a chase ends with a seeded
coin toss (40 % caught) instead of a footrace, and a meeting happens on arrival at the person's
current door.

Personas: **dutiful** says yes and pays · **rebel** refuses and runs · **talker** talks to gangs
first and picks choices by hash · **drifter** picks choices, payments and running by hash.

| # | Seed | Persona | Real min | Game h | Plot → ending | Side arc | Deliveries | Gang / checkpoint | ¤ at end |
|---|------|---------|---------:|-------:|---------------|----------|-----------:|-------------------|---------:|
| 1 | 1337 | dutiful | 91 | 55 | Hidden Abundance → seed opened to everyone | Missing Child (found) | 51 | 0 / 0 | 104 |
| 2 | 2024 | rebel | 121 | 77 | Hidden Abundance → key thrown into the fog | Debt (refused) | 75 | 0 / 0 | 442 |
| 3 | 77 | talker | 76 | 51 | Plague → formula sold to the profiteer | Secret (kept) | 47 | 0 / 0 | 654 |
| 4 | 4242 | drifter | 106 | 64 | Hidden Abundance → key thrown into the fog | Missing Child (found) | 59 | 0 / 1 | 174 |
| 5 | 9001 | dutiful | 121 | 78 | Blackout → lights back on | Debt (paid) | 77 | 2 / 8 | 303 |
| 6 | 31337 | rebel | 60 | 36 | Plague → formula sold | Missing Child (found) | 40 | 0 / 1 | 469 |
| 7 | 555 | drifter | 91 | 55 | Hidden Abundance → key thrown into the fog | Missing Child (found) | 51 | 1 / 3 | 13 |
| 8 | 8080 | talker | 120 | 78 | Hidden Abundance → vault sold to the monopolist | Missing Child (found) | 81 | 0 / 1 | 968 |
| 9 | 123456 | dutiful | 100 | 63 | Plague → cure smuggled with a gang | Secret (kept) | 68 | 0 / 2 | 282 |
| 10 | 271828 | drifter | 111 | 74 | Hidden Abundance → vault given to the gang | Debt (refused) | 63 | 2 / 0 (2 chases, caught once) | 322 |

## The stories in short

1. **Seed 1337, dutiful — "The co-op named after Liv."** Liv Kendova (79) keeps a polished tin on
   her shelf. The courier gives her the last ration box, carries leaflets for the People's Lamp and
   is summoned the evening before Liv dies. Her last order: the tin, for the Lamplighter, whose
   burnt-out flat holds a key and a journal pointing to a founders' seed vault. Shiawick Agricorp
   offers money; the Ember Ghosts leave a cracked bowl on the doorstep. Suki, the ward friend, is
   beaten for knowing the courier; the courier pays the gang to leave Suki alone. The vault is
   opened to everyone, food prices fall, and the new co-op is named after Liv. On the side, Leon
   Bristrov's lost child turns up asleep in an empty flat.
2. **Seed 2024, rebel — "The key into the fog."** The same arc with Karel Beman as keeper and
   Zephyr as friend, refused at every turn: no questions about the tin, no leaflets, a race against
   the rival courier, revenge instead of protection money, and finally the key thrown off a high
   bridge. Prices keep climbing (×2.75 by day 4). Minh Yosdong, refused help with a gang debt,
   wakes to a new lock and a gang tag on the door.
3. **Seed 77, talker — "Selling the cure."** A cough runs through the lower floors. Klara Fudaerov
   (77) can't pay for medicine; Dr Liv Nastbeiman brews a cheap cure from samples the courier
   carries. Olesi-Zollton Medical seal the block for Criallyn Transit, and the courier sells them
   the formula: ¤600 richer, food prices soar. Side arc: love notes for Juno Zyn, kept secret from
   Alma Stismer.
4. **Seed 4242, drifter — keeper Imani Quassi (81).** Hidden Abundance again, choices by chance:
   the ration box to the friend, the key left with the patron, protection money for Rhys, then the
   vault locked and the key lost.
5. **Seed 9001, dutiful — "Lights back on."** Lights flicker; 89-year-old Nyx Thish says it was done
   on purpose. Engineer Nyx Wraexeth finds clean-cut cables, the courier smuggles relay parts from a
   Labostberg Grid store, and the saboteur Corin confesses the grid paid him to force a new
   contract. Offered the slips, the switch or the Chrome Teeth's money, the courier throws the
   switch; the block lights up and the dumpling shop gives out free noodles. Side: Ilse Lurga's gang
   debt paid off. The only run with a steady stream of checkpoints (8) and tolls (2).
6. **Seed 31337, rebel — plague, refused.** The courier won't carry the doctor's samples, yet the
   quarantine scene still talks about "Liv's cure", and the run ends selling a formula that was never
   made. The missing child is found. Shortest run, one night.
7. **Seed 555, drifter — keeper Rania Maoaaura (86).** Hidden Abundance ending with the key in the
   fog. Rent leaves the courier with ¤13 on day 3.
8. **Seed 8080, talker — "Sold to Kurov Harvest."** The vault is emptied by morning for ¤800 and
   prices stay high; Leila, the friend, stops answering the door. Richest run (¤968, silver licence).
9. **Seed 123456, dutiful — "The cure in noodle boxes."** The cure moves floor by floor with the
   Copper Ghosts, the cough fades, and the gang lets everyone know who owes them.
10. **Seed 271828, drifter — "The Hollow Dogs' seed."** The vault goes to the Hollow Dogs, who
    take every bridge as their price ("nobody hijacks your deliveries any more") and then charge
    the courier a toll that night, chase them and take three orders. Keeper and friend are both
    called Noor, so the ration choice reads "Take it to Noor. (not: Take it to Noor.)"

## What the runs show

- **Each main arc is over in 30–50 minutes of play.** Scenes chain back to back (rival, blight,
  ration choice and leaflets within an hour of game time), leaving the second half of a 2-hour
  session with nothing but deliveries.
- **Only 3 of 6 templates appeared** (Hidden Abundance 6×, Plague 3×, Blackout 1×); Election,
  Fall of a House and Descent never won the pick. Same-template runs read almost word for word
  alike apart from names.
- **Side arcs are two scenes long** and finish on day 1.
- **Rent breaks the first week:** the game starts on a Sunday, ¤900 rent falls due on Monday
  06:00 with ¤150 start credits, so 7 of 10 couriers were ¤380–550 in debt by day 2.
- **Bug, fixed:** in debt, paying a toll, a checkpoint or a rescue added money (`mini(price,
  credits)` with negative credits). Now nothing is paid and nothing gained.
- **Gangs barely show up:** 0–2 tolls per session and a single chase across all ten runs; most
  courier routes never cross a claimed bridge.
- **Continuity slips:** "Come tomorrow" and the keeper's death "in the night" land the same evening;
  a refused plague doctor still has a cure in the next scene; the gang given the vault still chases
  the courier; sentences start with a lowercase faction ("the Ember Ghosts send…"); two cast members
  can share a first name.
- **Doorsteps repeat:** six lines cover most of ~600 deliveries ("Finally, I'm starving." 23×).
- **No resident died of natural causes** in 3–4 days of the live simulation; deaths come only from
  the story.
