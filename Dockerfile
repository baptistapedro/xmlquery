FROM ubuntu:20.04 as builder

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get install -y build-essential tzdata pkg-config \
	wget clang git

RUN wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

ADD . /xmlquery
WORKDIR /xmlquery

ADD fuzzers/fuzz_parse.go ./fuzzers/
WORKDIR ./fuzzers/
RUN go install github.com/dvyukov/go-fuzz/go-fuzz@latest github.com/dvyukov/go-fuzz/go-fuzz-build@latest
RUN go get github.com/dvyukov/go-fuzz/go-fuzz-dep
RUN go get github.com/antchfx/xmlquery
RUN /root/go/bin/go-fuzz-build -libfuzzer -o harness.a
RUN clang -fsanitize=fuzzer harness.a -o fuzz_parse
RUN wget https://raw.githubusercontent.com/strongcourage/fuzzing-corpus/master/xml/mozilla/001.xml
RUN wget https://raw.githubusercontent.com/strongcourage/fuzzing-corpus/master/xml/mozilla/002.xml
RUN wget https://raw.githubusercontent.com/strongcourage/fuzzing-corpus/master/xml/mozilla/003.xml

FROM ubuntu:20.04
COPY --from=builder /xmlquery/fuzzers/fuzz_parse  /
COPY --from=builder /xmlquery/fuzzers/*.xml /testsuite/

ENTRYPOINT []
CMD ["/fuzz_parse"]
