default: test

benchmarks:
	swift run -c release swift-url-routing-benchmark

test:
	swift test \
		--parallel

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:6.3 \
		bash -c 'swift test --parallel'

format:
	swift format --in-place --recursive \
		./Package.swift ./Sources ./Tests
	find . -type f -name '*.md' -print0 | xargs -0 perl -pi -e 's/ +$$//'

generate-variadics:
	swift run variadics-generator > Sources/URLRouting/Builders/Variadics.swift

.PHONY: benchmarks format generate-variadics test test-linux
