# simple makefile to simplify repetitive build env management tasks under posix
# this is adopted from the sklearn Makefile

# caution: testing won't work on windows

PYTHON ?= python

.PHONY: clean
clean:
	$(PYTHON) setup.py clean
	rm -rf dist
	rm -rf build
	rm -rf .pytest_cache
	rm -rf pmdarima.egg-info

.PHONY: deploy-requirements
deploy-requirements:
	$(PYTHON) -m pip install twine readme_renderer[md]

# Depends on an artifact existing in dist/, and two environment variables
.PHONY: deploy-twine-test
deploy-twine-test: bdist_wheel deploy-requirements
	$(PYTHON) -m twine upload \
		--repository-url https://test.pypi.org/legacy/ dist/* \
		--username ${TWINE_USERNAME} \
		--password ${TWINE_PASSWORD}

.PHONY: doc-requirements
doc-requirements:
	$(PYTHON) -m pip install -r build_tools/doc/doc_requirements.txt

.PHONY: documentation
documentation: doc-requirements
	@make -C doc clean html EXAMPLES_PATTERN=example_*

.PHONY: requirements
requirements:
	$(PYTHON) -m pip install -r requirements.txt

.PHONY: bdist_wheel
bdist_wheel: requirements
	$(PYTHON) setup.py bdist_wheel

.PHONY: sdist
sdist: requirements
	$(PYTHON) setup.py sdist

.PHONY: develop
develop: requirements
	$(PYTHON) setup.py develop

.PHONY: install
install: requirements
	$(PYTHON) setup.py install

.PHONY: test-requirements
test-requirements:
	$(PYTHON) -m pip install pytest flake8 matplotlib pytest-mpl pytest-benchmark

.PHONY: coverage-dependencies
coverage-dependencies:
	$(PYTHON) -m pip install coverage pytest-cov codecov

.PHONY: test-lint
test-lint: test-requirements
	$(PYTHON) -m flake8 pmdarima --filename='*.py' --ignore E803,F401,F403,W293,W504

.PHONY: test-unit
test-unit: test-requirements coverage-dependencies
	$(PYTHON) -m pytest -v --durations=20 --mpl --mpl-baseline-path=etc/pytest_images --cov-config .coveragerc --cov pmdarima -p no:logging --benchmark-skip

.PHONY: test-benchmark
test-benchmark: test-requirements coverage-dependencies
	$(PYTHON) -m pytest -v --durations=12 --mpl --mpl-baseline-path=etc/pytest_images --cov-config .coveragerc --cov pmdarima -p no:logging --benchmark-min-rounds=5 --benchmark-min-time=1 --benchmark-only

.PHONY: test
test: develop test-unit test-lint
	# Coverage creates all these random little artifacts we don't want
	rm .coverage.* || echo "No coverage artifacts to remove"

.PHONY: twine-check
twine-check: bdist_wheel deploy-requirements
	# Check that twine will parse the README acceptably
	$(PYTHON) -m twine check dist/*

.PHONY: VERSION
VERSION:
ifneq ($(GIT_TAG),)
	@echo "Tagged commit, writing to VERSION file"
	@echo $(GIT_TAG) > pmdarima/VERSION
else
	@echo "Not a tagged commit, will not write to VERSION file"
endif
