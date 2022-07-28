Write an essay, in your own words, explaining your thought process and what you felt were the hardest problems to solve.

I chose task 3, which was a pretty straightforward decision, as it was the most interesting one for me. 
At first, I created 2 contracts and added some boilerplate (not working, more like an interface not to forget functions that I have in mind)
Then I added required modifiers and checks inside my functions, to prevent error flow
After that, I started improving/fixing my functions to be working :) At that moment I had to come up with mappings for proposals/vote on proposals/remove votes/... data structures -- this was one of the hardest moments for me. The hardest one I think was the next -- creating mappings for votes delegation. I spend quite a time and I still think there's room for improvement, but I left it as it is.
Then it was just prettifying the code -- formatting, adding events, error messages, optimizations (memory -> call data) renaming here and there.
The last big leap was creating tests, which also took a couple of hours as I've never written any solidity tests and had to read some foundry docs. Glad that I decided to do it, cause I've found 2-3 errors in my code during testing.

What could be improved:
    - Creating interfaces and TDD probably should be the first step
    - Not sure in my data structures, probably it was possible to make better ones
    - Don't know how to write errors properly, on one hand, I like using require for such things, on the other -- defining `error Asdf()` in a contract's body inside just text in require looks more straightforward to me (and also easier in testing)
    - More tests, but I was pretty tired with writing the original ones and I think I've covered most of the cases :)