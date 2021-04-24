use core::cmp::max;
use std::io;
use std::io::BufRead;

fn main() -> Result<(), std::io::Error> {
    let mut pokemons: usize = 0;
    let mut starters = [false, false, false];

    for line in io::stdin().lock().lines() {
        let line = line?;
        if let Some(starter) = parse(&line, "starters") {
            starters[starter] = true;
        } else if let Some(pokemon) = parse(&line, "pokemons") {
            pokemons = max(pokemon + 1, pokemons);
            println!("{}", line);
        } else {
            println!("{}", line);
        }
    }

    for (i, _) in starters.iter().enumerate().filter(|(_, s)| **s) {
        println!(".starters[{}]={}", i, rand::random::<usize>() % pokemons);
    }
    Ok(())
}

fn parse(line: &str, field_name: &str) -> Option<usize> {
    let rest = line
        .strip_prefix('.')?
        .strip_prefix(field_name)?
        .strip_prefix('[')?;
    let idx = rest.split(']').next()?;
    idx.parse::<usize>().ok()
}
