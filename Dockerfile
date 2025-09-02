FROM alpine:3.22
RUN apk add build-base git
RUN git clone https://github.com/wolfcw/libfaketime /usr/local/src/libfaketime
WORKDIR /usr/local/src/libfaketime
RUN git checkout 4fc06b90df8098b9dedb54a7d3e08653db1c9380 && make && make install

# Library is in
# - /usr/local/lib/faketime/libfaketimeMT.so.1
# - /usr/local/lib/faketime/libfaketime.so.1

# Verify in Alpine

FROM alpine
COPY --from=0 /usr/local/lib/faketime/libfaketimeMT.so.1 /lib/faketime.so
ENV LD_PRELOAD=/lib/faketime.so
ENV FAKETIME="-15d" 
ENV DONT_FAKE_MONOTONIC=1
RUN date && touch /tmp/dummy

# Verify with Java

FROM groovy:alpine
COPY --from=0 /usr/local/lib/faketime/libfaketimeMT.so.1 /lib/faketime.so
ENV LD_PRELOAD=/lib/faketime.so
ENV FAKETIME="-15d" 
ENV DONT_FAKE_MONOTONIC=1
RUN groovy -e "System.out.println((new Date()).toInstant());" && touch /tmp/dummy

# Build the final image
FROM scratch
COPY --from=1 /tmp/dummy /dev/null
COPY --from=2 /tmp/dummy /dev/null
COPY --from=0 /usr/local/lib/faketime/libfaketimeMT.so.1 /faketime.so
