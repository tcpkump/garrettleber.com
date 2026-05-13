---
title: "Gregtech: New Horizons is a pretty neat Minecraft modpack"
date: 2026-05-10T12:54:12-0400
socialShare: false
draft: true
author: "Garrett Leber"
tags: ["minecraft"]
image: ""
description: "I've been enjoying GTNH lately, and just feel like talking about it."
---

I'm back in my semi-annual Minecraft phase right now, and this time I'm back on Gregtech: New Horizons (referred to as
GTNH from here on out). I've found it to be a really relaxing way to spend my evenings lately. For those who aren't
familiar, this is a Minecraft modpack that has a bit of a reputation for being incredibly difficult. It takes thousands
of hours to "beat" the pack. It might sound strange to say that I find Minecraft's most difficult pack relaxing, but
that's actually because I disagree with that assessment entirely. The pack just has tons and tons of content, and an
incredible questbook/wiki, with a large community around it to make any hurdle easy to navigate. For this reason, it
fixes my issue in vanilla where I login to my forever world and can't think of something to do. It's all laid out very
clearly in front of me, but allows for many branches to explore at each point still. I can login each night and expand
my machinery, improve automation for some resources, farm, decorate my base, or explore, it's open to whatever I feel
like doing. The best part is that I always feel like I'm progressing, and there's always something ahead of me. The best
part of the pack _is_ the fact that it takes thousands of hours to finish. By accepting that I will likely never
actually finish it, I actually play it to enjoy the journey rather than always trying to get to the next big thing.

Right now I am in the middle of going from the Low Voltage (LV) tier to the Medium Voltage (MV) tier. One thing I've hit
that I've needed to work on is improving my power generation. Up until now, I've been using steam power and semifluid
generators running on creosote. I've actually automated the power generation for both of these already, but the energy
output is just not enough to sustain my needs for MV. MV machines consume 4x the power of LV machines. When using steam,
its a bit over 6,000 liters of steam per second. As a point of reference, I make about 14,000L/sec total right now, and
tend to have 5+ machines processing at a time. One can see how this isn't sustainable. I only use my semifluid
generators for smaller on-demand work, because it's pretty inefficient, and creosote generation is a slow process.

There's a few options for me to move into for power generation in MV. I'll start with what I've ruled out. Expanding the
steam generation could work, but I'm choosing not to because it would be quite the effort, and would not be useful for
any further tiers. At that point steam gets pretty unreasonable as a power source (think of High Voltage, which is 4x
MV). Creosote isn't useful for previously stated reasons, similar to steam but it already would take tons of
infrastructure to generate enough creosote for my needs. Benzene is a power source that I would really like to use, and
have started using in a limited capacity. This is a product of processing wood and charcoal, which is what is used for
my creosote generation at the moment. The problem now is with the materials I currently have, the machines I could make
are pretty inefficient at benzene production, so they don't come out with much surplus power at the end. In the near
future, I could get 200% efficiency, so the plan is to use benzene when I can do that.

With all that said, I've landed on using diesel as my current power source for MV. Diesel is created through a several
stage processing pipeline of oil. It's stuff like this that i find really run in the modpack. To give an idea of the
process here, I'll briefly outline what I can recall from memory. I use an oil pump to get raw oil from oil spouts that
I can find throughout my world. I then manually transport that oil back to my base. From here, we need to split the oil
between two processes, light fuel production and heavy fuel production. Combining light and heavy fuel is how we get
diesel. I haven't walked down the heavy fuel path yet, but last night I got most of my automated infra down for the
light fuel, so I'll cover that. Oil goes into a distillery to make sulfuric light fuel. This also has a byproduct that I
process back into hydrogen in a closed loop which feeds into the next step. The sulfuric light fuel then goes into a
chemical reactor with the hydrogen to create light fuel. Earlier processing of the hydrogen also creates sulfar as an
additional byproduct that I can use for other processes.

Doing all that manually every time I want to make fuel would be extremely tedious, and isn't in the spirit of the pack.
It gives many tools to automate this process, so I get to spent time figuring out how I want to place my machines with
their power cables, item and fluid pipes, and storage (like tanks and drawers). It's a pretty fun problem-solving
process, with no urgency.

---

<!--
OUTLINE / REWRITE GUIDE — delete this section before publishing

## 1. Intro: Why is the "hardest pack" relaxing?
- Semi-annual Minecraft phase, back on GTNH
- Reputation for being brutally difficult / thousands of hours to finish
- Why that's actually a feature: incredible questbook/wiki, huge community, always something to do
- Contrast with vanilla "login and stare at your forever world" problem
- The key insight: accepting you'll never finish means you play for the journey
- NOTE: "best part" is used twice in this paragraph in the draft — fix that

## 2. The Voltage Tier System (scale context)
- GTNH progression is organized into 14 voltage tiers: ULV, LV, MV, HV, EV, IV, LuV, ZPM, UV, UHV, UEV, UIV, UMV, UXV
- Each tier is 4x the power of the previous
- We are on tier 2 (LV) transitioning to tier 3 (MV) — this post is about a tiny slice of a very long journey
- Good place to set expectations: this is a zoomed-in look at one specific problem in one specific transition

## 3. Where I Am Right Now: LV → MV
- Brief description of what LV and MV mean in practice
- MV machines consume 4x the power of LV machines
- Currently running steam power + semifluid generators (creosote)
- Both are automated, but output can't sustain MV workloads
- Numbers: ~14,000 L/s steam total, steam machines use ~6,000 L/s each, 5+ machines running at a time

## 4. The Power Problem
- Do the math: current steam output vs. what MV demands
- Semifluid/creosote is inefficient and slow to produce — only used for smaller on-demand work
- Need a new power source before I can really move into MV

## 5. Options Considered and Ruled Out
- **Expanding steam**: possible but huge effort, and doesn't scale past MV (HV would be 4x again — gets absurd fast)
- **More creosote**: same scaling problem, and even more infrastructure needed just to meet current needs
- **Benzene**: really want to use this — processed from wood/charcoal (same feedstock as creosote)
  - Problem: current machines are too inefficient, not worth it yet
  - At 200% efficiency it becomes very attractive — that's the near-future plan
  - Tease: benzene might get its own post

## 6. Diesel: The Chosen Path
- Multi-stage oil processing pipeline — this is the kind of thing that makes the pack fun
- Overview of the pipeline from memory:
  - Oil pump → raw oil from oil spouts in the world (manually transported back to base for now)
  - Split oil into two paths: light fuel and heavy fuel (both needed to combine into diesel)
  - **Light fuel path (DONE + automated):**
    - Distillery: oil → sulfuric light fuel (byproduct → hydrogen, closed loop into next step)
    - Chemical reactor: sulfuric light fuel + hydrogen → light fuel
    - Earlier hydrogen processing also yields sulfur as a bonus byproduct
  - **Heavy fuel path (scaffolded, not PoC'd yet):**
    - Infrastructure is laid out but haven't been able to actually run it
    - Blocked on materials needed to build the right machines — not there yet
- Why this matters: without automation, this is what the manual loop looks like:
  - Manually distill oil → sulfuric light fuel → grab with fuel cells by hand
  - Move to chemical reactor → scrounge for hydrogen or go make some via a separate process
  - End result: a stack of light fuel cells (64 buckets worth) in your hand
  - That stack lasts ~2 hours of MV machines running constantly
  - You'd be doing this loop over and over just to keep the lights on

## 7. Automation: The Actual Fun Part
- Setting up the pipeline is the game — placing machines, running power cables, item and fluid pipes, tanks, drawers
- No urgency, just a fun problem-solving sandbox
- Consider: add a specific funny/concrete moment from setting this up (a pipe in the wrong place, a tank overflowing, etc.) to make this section less generic

## 8. What's Next: Benzene
- Light fuel is running, heavy fuel is next once I have the materials to build the machines
- After that, diesel is fully online
- But the real goal down the road is benzene — more efficient, same feedstock I'm already using for creosote
- Hint that this might be the next post
-->

---


I'm back in my semi-annual Minecraft phase right now, and this time I'm back on Gregtech: New Horizons (referred to as
GTNH from here on out). I've found it to be a really relaxing way to spend my evenings lately. For those who aren't
familiar, this is a Minecraft modpack that has a bit of a reputation for being incredibly difficult. It takes thousands
of hours to "beat" the pack. It might sound strange to say that I find Minecraft's most difficult pack relaxing, but
that's actually because I disagree with that assessment entirely. The pack just has tons and tons of content, and an
incredible questbook/wiki, with a large community around it to make any hurdle easy to navigate. For this reason, it
fixes my issue in vanilla where I login to my forever world and can't think of something to do. It's all laid out very
clearly in front of me, but allows for many branches to explore at each point. I can login each night and expand my
machinery, improve automation for some resources, farm, decorate my base, or explore, it's open to whatever I feel like
doing. I always feel like there's something ahead of me. The best part of the pack _is_ the fact that it takes thousands
of hours to finish. By accepting that I will likely never actually finish it, I actually play it to enjoy the journey
rather than always trying to get to the next big thing.

## The Tier System

GTNH gates progression behind a [tier system](https://wiki.gtnewhorizons.com/wiki/Tier) consisting of 15 different
tiers. Almost universally, each subsequent tier requires 4x the power of the previous tier. The only exceptions to this
that I'm aware of are stone and steam, which are before you have electricity. The LV (Low Voltage) tier sets the bar,
with machines requiring 32EU/tick (energy units). Don't worry, understanding the units for the purposes of this post
isn't very important, just seeing the relationships between them. So, currently I'd say I'm right in between LV and MV
(Medium Voltage),
which is still very early game for GTNH. I have around 150 hours on this save, for reference. The wiki says that it
takes around [2500 hours](https://wiki.gtnewhorizons.com/wiki/Beginner_Tips#Target_Audience) for an *experienced* solo
player. To me that reads that the player has played the pack before, another couple thousand hours... What I'm getting
at is that in this post we are looking at a very small piece of a very large picture.

What is LV and MV really? LV is the first big "break" in the game that brings with it great strides in the efficiency of
material processing. What a mouthful. This is best illustrated with an example. Making iron plates in the stone age
requires using a hammer and two iron ingots. At first you'll be smelting one iron ore into a single ingot. In the steam
age you get to improve both sides of this process. You can double your ore processing, so you get two ingots, and you
get access to the Forge Hammer, which lets you create 2 plates with 3 ingots. Then, when you get to LV, you can process
your ingots into plates 1:1. Most people power their first LV machines with steam using a steam turbine, but they tend to consume *much* more
steam than actual steam machines. So I've just started dabbling in MV machines, which again take 4x the power (128EU/tick) of LV machines. My LV power sources are just not able to keep up with MV demands, so I immediately have to revisit my power generation. Right now, I generate around 14k Liters of steam per second, and an LV steam turbine uses about 1500L/s of steam. As you might have figured, MV would demand around 6000L/s of steam. I tend to be running 5+ machines for various processes at any given time, so this isn't sustainable. I have switched most of my LV machines to using creosote with semifluid generators, which also works well, but to keep a long story short, it also wouldn't be able to keep up with MV demand. Expanding either of these power sources can very quickly become unweildy, requiring dozens of generators or coke ovens (just trust me, it's an effort).
