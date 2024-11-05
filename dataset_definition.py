from ehrql import Dataset, years, case, when, maximum_of
from ehrql.tables.core import patients

dataset = Dataset()

year = patients.date_of_birth.year
dataset.define_population(year >= 1940)

dataset.year = year

dataset.age = patients.age_on("2023-01-01")

# dataset.configure_dummy_data(population_size=10)
dataset.configure_experimental_dummy_data(population_size=10)
