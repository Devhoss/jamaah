# In-flight mode — plan

Agreed with the owner on 2026-10-14. The app is used by cabin crew and travellers;
on a flight there is no network, the phone's clock may be on any zone, and the
compass is unreliable inside the aircraft. GPS works in airplane mode and gives
position, altitude, ground speed and course, which is everything this needs.

## Decisions

- **Times as seen from the aircraft.** Sunrise and Maghrib follow the sun as it
  actually rises and sets at the aircraft's altitude: the horizon dips by about
  1.76′ × √(height in metres), roughly 3° at cruise, so the sun sets later than on
  the ground below. Fajr and Isha keep the method's angles; an Isha set as minutes
  after Maghrib moves with Maghrib. Dhuhr and Asr do not depend on altitude.
- **Opened from travel mode.** With travel mode on, Today shows an "On a flight?"
  card that opens the in-flight screen. Nothing new on the top bar.
- **Notifications from the projection** (phase 2). While in-flight mode is on, the
  next prayer is projected along the route and alerted; the regular notifications
  for the last place pause meanwhile.
- **Two phases.**
- **Out of scope:** travel rulings (shortening, combining).

## Phase 1 — here and now

- Precise location only when the in-flight screen is opened, after an explanation
  ("sit by a window"). GPS from the platform's location manager, so it works with
  no network; a fix every 30 s or so while the screen is open, none after.
- The zone where the aircraft is, from the bundled time-zone map.
- Shows: the current prayer period and the next prayer, "in N min" and at what
  time on the phone's clock; how much later sunset or sunrise is than on the
  ground; altitude, ground speed and position; the age of the fix.
- Qibla relative to the aircraft: the Qibla bearing from the current position
  minus the GPS course (close to the aircraft's heading, within a few degrees of
  wind drift), drawn on an aircraft outline as "N° to the right of the nose".
  A heading typed in from the seat-back map overrides the GPS course.
- Honest states: waiting for GPS, GPS lost (last fix and its age), on the
  ground (no course while standing still), permission refused.

## Phase 2 — along the route

- Project the position forward along the current great-circle course at the
  current ground speed, and find when the sun crosses each prayer's threshold
  at that moving point. Show "Maghrib in about 1 h 40 min along this route".
- Schedule one alert for the next projected prayer; refresh it with each fix;
  pause the regular notifications for the last place while in-flight mode is on,
  and restore them when it ends.

## Tests

Horizon dip; altitude 0 matches the ground sunset; cruise altitude delays sunset
by the expected amount at known latitudes; Qibla relative to a course, including
wrap-around; the screen's states with a fake GPS stream.
