---
layout: post
title: Notes on leading projects as a software engineer
thumbnail: "https://gsnaps.s3.us-west-2.amazonaws.com/monkey-island-trials.png"
permalink: /notes-on-leading-projects-software-engineer
excerpt_separator: <!--more-->
---

![trials](https://gsnaps.s3.us-west-2.amazonaws.com/monkey-island-trials.png)


A successful software project has many parts and many people contributing to it. What I want to focus on here is the role that a software engineer can play when they are leading the tech function.

At PN we call this role "solutions engineer", it is sometimes called "project lead" or "lead engineer".

My goal is to clarify my own thinking on this topic as well as giving insipiration to others that are holding a similar role or are interested in taking it.

<!--more-->

# Defining the role

As the engineers in charge of the project a lot of things are our responsibility. Because we are familiar with the requirements as well as the implementation often we have the most accurate picture and that is a big opportunity for contributing beyond writing code.

Fulfilling the expectations of this role means enabling the team to deliver "good work" defined as:
- on time
- on budget
- according to spec


# What to focus on

I believe that **shipping is the most important thing**.
Shipping means delivering the feature in a way that satisfies the requirements of the customer as defined by product.

Shipping requires to **balance code quality and maintainability with meeting deadlines**. 
In my experience shipping early gives the greater benefit because it reduced the time to new information.

# How to focus on it

## Limiting scope

This is probably one of the most difficult parts of our work.
During every phase of the project product and design will almost invariably ask for more scope, other engineers (and often ourselves) will push for higher quality and/or a solve that is more future-proof.

**The temptation to add scope is always strong**: if we paint ourselves in a corner mistakes will be painful.
I find that reminding yourself of the end goal - delivering value to customers - helps me to to keep perspective.

The biggest lever that we have to ensure that projects ship on time is **cutting scope**, it's not the only option but to me it's the most effective.

Cutting scope allows us to hone in on what's the core value proposition for the customer and focusing on delivering that first and putting it in front of them as soon as possible.

The goal is to ship fast, quickly testing what's being coded and ideally getting the feature in front of real users even before the planned deadline. 

## Feature flags

I believe in **feature flags vs feature branches**. Even if they can make the code a bit messy and require cleanup, in my experience they are a fantastic tool. They allow us to have new code be as close as possible to production and avoid the pain of long running branches.

## Beyond writing code

As the engineers in charge, we should be as familiar to the feature as much as the product owner if not more. 
Engineers are not "just doing" what is requested in the ticket, they are integral part of building the product and they have a unique perspective because they can see it from ideation to delivery.

## The value of Timeboxing

I found that timeboxing projects and keeping the scope small works best. A project should never take more than 6-8weeks to be in front of users.

Once again, **the goal is to DELIVER VALUE to customers as quickly as possible so the team can test its hypothesis.**

The second benefit is that timeboxing projects to a small size reduces the amount of time spent doing the "wrong thing" - if the project goes "off track" it will do so only for a few weeks.

When you start doing this it might feel like this is an impossible ask, **surely some problems can't be solved in 6 weeks**.
And you are right, they can not, and that's OK.
**What is always possible in my experience is breaking down a problem** into smaller problems that CAN be solved in 6 weeks.
Sometimes this will mean releasing something only internally, other times it will mean shipping alpha to a small subset of trusted users.

Focusing on small cycles will produce shorter feedback loops and force the team to create working shippable software that can be used to gather more information and iterate toward the end goal.

## Evaluating Risk

A big part of the job is making technical decisions, here are some of the things I usually think about:

- operational burden for production and staging environments
- operational burden for development
- new operational financial costs
- migrations
	- getting existing users on the feature
	- moving existing data

# The phases of a project
Projects can be broken down in 3 parts:
 - planning
 - building
 - release/support
 
The solutions engineer can help in different ways during each one of these.

## How to help planning
Here are some questions that I think through when working with product/design on project scoping and planning:

- Is the problem clear?
- Is this the smallest version of the problem we can be solving?
- How can I help product refine the proposed solution to something that can be done in 8 weeks max (ideally 6 + 2 of testing/shipping)?
	- there is always a way to break things down,  maybe that means having internal deliveries. Maybe it means shipping something smaller and making the problem smaller
- What are the capabilities of the current system?
- How can I morph the solution from product/design into something that can be easily fit on what's already there?
- How can I validate the new tech ideas we are considering?
- How can I identify the risks for the project?
- How can I break down the work into small stories, **that will not take more than a week to deliver?**

## During the build phase
- **Avoid long running PRs**. Long running stories mean long running PRs Long running PRs mean more context loaded for everyone.  This also means longer reviews and longer turnaround.
- **Cut scope**, ruthlessly. Resist the urge to do more and add more, focus only on what's necessary. The thing that matters the most is what the customer will experience. YAGNI is a very useful principle.

## During Release - Project delivery checklist
This is a list of things I think about and do when I have to plan and deliver a project. I encourage you to build your own list based on your needs.

### Release planning
 
I find helpful to plan the release in advance and consider a few things:

- Think about the current state of the system and the future state of the system when the feature flag goes live.
	- What will need to be different?
	- What will need to be the same?
	- What is going to be the experience for users that have the app already open on their browser?
	- What is experience for new users that just purchased?
- Map out all the scenarios you can think of for existing and current users, think them through and test them
	- Imagine what experience each type of user will have and verify your assumptions
- Consider how the team could release something earlier to a smaller subsets of users to test your assumptions and their experience.

### Things to during release
- Test the feature as the user. I do this directly in production before the feature is released widely.
- Monitor the performance of the system as affected by the feature after it goes live.
- Check the data collected (i.e new entries in the database), Ideally I define expectations on what the data should look like after 1h, 1day, 1week and check on them at set intervals.
- Look at the incoming bug-reports, looking for things that might be related to what was just released.

## After delivery
Cleaning up is important, part of this process produces some craft that requires to be dealt with.

It's helpful to ensure that tickets to remove feature flags are ready and scheduled for after delivery.

It's also important to leave the project in a state that will allow us or someone else to continue work on it later on.
Usually the end of the project is when we are the most clear about what we could have done differently and what needs fixing. It's also when there is no time to do so. 
Leave your future self (or someone else) notes/tickets on what can be improved.

# Conclusion

I hope this post helps you in your engineering roles, whatever they are.
Everyone is different and everywhere is different and you will need to find your way to solve the problems that are unique to your situation.
These things have worked for me and the teams I've been a part of in the last few years.

If you read this and want to discuss these ideas feel free to reach out!


## Resources
People smarter and more experienced than me have written a lot on this topic, here's some of my favorites pics:
- [Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/) is a great and approachable introduction to these topics.
- [Charity Majors post on CD](https://charity.wtf/2021/02/19/how-much-is-your-fear-costing-you/), pretty much everything in this blog is worth reading.
- [Chelsea Troy's guide on leveling up for programmers](https://chelseatroy.com/2018/04/20/leveling-up-a-guide-for-programmers/), in general I find this blog is a goldmine.
- [Software estimation without guessing](https://pragprog.com/titles/gdestimate/software-estimation-without-guessing/), is worth a read if you wanna improve your estimation game.
- [Shape Up](https://basecamp.com/shapeup) has had a major impact on how a lot of companies think about projects.


## Thanks

Many thanks to [@typeoneerror](https://twitter.com/typeoneerror) and [@benjamintmoss](https://twitter.com/benjamintmoss) for their feedback on this article.
