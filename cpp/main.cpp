#include <array>
#include <cstdio>
#include <iostream>
#include <random>
#include <string>

int main() {
    size_t pokemons = 0;
    std::array<bool, 3> starters;

    for (std::string line; std::getline(std::cin, line);) {
        unsigned int index, value;
        if (sscanf(line.c_str(), ".starters[%u]=%u", &index, &value) == 2
            && index < starters.size()) {
            starters[index] = true;
        } else {
            if (sscanf(line.c_str(), ".pokemons[%u]", &index) == 1)
                pokemons = pokemons < index ? index : pokemons;

            std::cout << line << "\n";
        }
    }

    std::default_random_engine gen;
    std::uniform_int_distribution<size_t> dist(0, pokemons-1);
    for (size_t i = 0; i < starters.size(); i++) {
        if (!starters[i])
            continue;

        std::cout << ".starters[" << i << "]=" << dist(gen) << "\n";
    }
}
