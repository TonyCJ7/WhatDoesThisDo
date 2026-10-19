print(PyConfig().run())


class PyConfig:
    def run(self):
        return PY_LIMIT + self.py_attempt(1)

    def py_attempt(self, n):
        return n


PY_LIMIT = 3
