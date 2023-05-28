# garrettleber.com

This repo holds the both the frontend and backend code for my personal website. The frontend is a static site generated using Hugo and the backend is using AWS Serverless technologies deployed via Terraform.

## Frontend

I chose to use Hugo as my static site generator because it is fast, easy to use, and has a large community. For the theme, I chose [Hugo-Profile](https://github.com/gurusabarish/hugo-profile). Hugo is also extremely useful for creating a blog, which I plan on using to improve my engagement with the community.

## Backend

The backend is deployed using Terraform and AWS Serverless technologies. The backend is composed of the following AWS services:

- API Gateway
- Lambda
- DynamoDB
- S3
- CloudFront
- Route53

## CI/CD

I am using GitHub Actions to deploy the frontend and backend. I also incorporate dynamic code that passes things like the CloudFront distribution ID and the S3 bucket name to the frontend code. This way I reduce the amount of manual work I have to do when deploying (or redeploying) the site.
