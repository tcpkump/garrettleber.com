---
title: "Building a static site with Hugo and github actions"
date: 2023-05-24T18:30:43-04:00
socialShare: false
draft: false
author: "Garrett Leber"
tags:
image: /images/hugo.jpg
description: "My experience building a static site with Hugo and github actions"
---

I've toyed with many ways of creating static websites over the years. I've done bare HTML/CSS with no frameworks, I've used bootstrap, I've used Jekyll, and I've used Hugo. One thing that has been consistent is my hosting via S3 and Cloudfront (among other pieces). However, this post will remain focused on what I consider the front end of the site, and not the hosting (we're saving that for another post). Out of all of the static sites I've developed, Hugo has been my favorite. It's fast, easy to use, and has a large community. For the theme, I chose [Hugo-Profile](https://github.com/gurusabarish/hugo-profile) because it allows me to have a clean homepage with a resume (both in HTML and PDF format) and a blog. I also like the fact that it's a single page application, so it's fast and easy to navigate.

## My experience with Hugo

I'll admit there has been a little bit of a learning curve with Hugo. I started out by following the [quickstart](https://gohugo.io/getting-started/quick-start/) guide, and then I swapped out the theme. This is where I started to actually develop my site.

Immediately, the Hugo-Profile documentation advises you to `git clone` directly into your themes directory. I did this, but encountered issues later when I wanted to commit my changes to my own repository. This led me to learning about git submodules, which are pretty neat. I had to remove the hugo-profile repo from my theme directory and simply readd it as a submodule. This allows me to commit my changes to my own repo, and pull in updates from the hugo-profile repo.

The necessary command to do this is:

```bash
git submodule add https://github.com/gurusabarish/hugo-profile.git themes/hugo-profile
```

Once you have the theme, I think it is normal to dive into loading your content onto the landing page, which is what I started doing. I did this a bit manually, copying info from my previous site and pasting it in, formatting it as markdown. One custom thing I keep around on my sites is a visitor counter I developed as part of the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) so this led me down a rabbit hole of customizing the footer on my Hugo theme. Hugo has a system built-in where you can override the default theme files by creating your own files in the same directory structure. This is what I did to override the footer. I created a `layouts/partials/sections/footer/copyright.html` file and added my custom code there. This worked great, and I was able to get my visitor counter working. One downside I see for this is that I won't get any updates to the footer from the theme, but I'm not too worried about that.

## Adding a blog

The theme comes out of the box with a link to a blog, but it doesn't actually have a blog. I wanted to add a blog, so I started by following the hugo docs to add a new page.

The necessary command to do this is:

```bash
hugo new blogs/hugo-static-site.md
```

Then I got to typing this page up, how fun.

## Adding github actions

Really all we do here is set up our github actions to build the site and deploy it to S3. I'll leave it as an exercise to the reader to figure out how to do this, but I'll give you a hint: If you are using a CDN like Cloudfront, you should also invalidate the cache on deploy.

## Conclusion

I know I didn't go into much technical detail here, but I really don't think there is too much I would want to go into (yet, maybe). If you are interested, everything for this site is open source and available on [github](https://github.com/garrettleber/garrettleber.com). I hope you enjoyed this post, and I hope you enjoy my site!
