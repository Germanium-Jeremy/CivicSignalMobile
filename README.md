# CIVICSIGNAL

## PROBLEM STATEMENT

In our community, reporting civic issues like potholes, broken streetlight, and public safety concerns is fragmented and ineffective. Citizens face three main challenges: not knowing the correct reporting channels, experiencing frustration with lack of follow-up, and having no transparency in resolution processes. This leads to unresolved community issues, citizen dissatisfaction, and inefficient government resource allocation.

## OUR SOLUTION

`CivicSignal` is a platform that simplifies civic reporting and creates accountability through public tracking. Our `mobile app` enables citizens to report any non-emergency civic issue in under 40 seconds using category-based reporting, automatic GPS location capture and photo documentation. Our `web based platform` enables agencies, private authorized companoes, monitor issues related to their services, organize them based on desired criterias and track resolution process. Each report receives a public tracking number with status updates, creating transparency from submission to resolution.

## UNIQUE VALUE PROPOSITION

We bridge the gap between citizens and local government by transforming chaotic complaints into structured actionable data. Unlike scattered social media complaints or forgotten phone calls, `CivicSignal` provides a centralized, accountable system that benefits both citizens and municipal authorities.

## IMPACT METRICS

Success will be measured by:

- 40% reduction in average issue resolution time
- 300% increase in citizen reporting participation
- 75% user satisfaction rate
- Improved government efficiency metrics

## CALL TO ACTION

We are seeking support through this competition to launch our pilot program and demonstrate the trans-formative potential of civic technologies in creating more responsive, transparent local governments.

# What to try it out? Web Platform <a href="https://civic-signal.vercel.app" target="_black">Web Platform</a> or download our mobile application <a href="https://expo.dev/accounts/djeremiah/projects/civic-signal/builds" target="_blank">Mobile App</a>

## Enterprise Runtime Configuration

Add these environment variables for production-grade sessions and cache:

```env
REDIS_URL=redis://<username>:<password>@<host>:<port>
SESSION_TTL_SECONDS=604800
JWT_SECRET=<strong-random-secret>
JWT_REFRESH_SECRET=<strong-random-secret>
```

- `REDIS_URL`: shared Redis instance used for API response caching and server-side sessions.
- `SESSION_TTL_SECONDS`: server session lifetime (defaults to 7 days).
