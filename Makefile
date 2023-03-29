default: test

benchmarks:
	swift run -c release swift-url-routing-benchmark

test:
	swift test \
		--enable-test-discovery \
		--parallel

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7 \
		bash -c 'make test'

format:
	swift format --in-place --recursive \
		./Package.swift ./Sources ./Tests
	find . -type f -name '*.md' -print0 | xargs -0 perl -pi -e 's/ +$$//'

generate-variadics:
	swift run variadics-generator > Sources/URLRouting/Builders/Variadics.swift

.PHONY: benchmarks format generate-variadics test
