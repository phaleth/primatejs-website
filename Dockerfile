FROM python:3-alpine AS builder

ENV BRANCH_NAME=master

RUN apk add --no-cache --update \
  curl; \
  pip install mkdocs; \
  pip install mkdocs-material;
   
RUN curl https://codeload.github.com/primatejs/website/tar.gz/${BRANCH_NAME} | tar -xz; \
  mv website-${BRANCH_NAME} website;

WORKDIR /website

RUN python -m mkdocs build

FROM nginx:mainline-alpine

COPY --from=builder /website/site /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

