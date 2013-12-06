dfwbot
======

Some simple proof of concept IRC bots built on Bot::BasicBot

One is a greeter bot (it just says hi)

One is a spell checker bot (it checks your psellling)

One is a dictionary bot (it looks up word definitions) if you use this, get your own API key

One is a bare-bones bot that takes plugins in the form of Moose roles (examples provided)

Note to developers: If using Par::Packer (pp) to compile your bot and its plugins, you'll
need to do it like the example below:

    pp -I . \
       -M Bot::BasicBot \
       -M POE::Pipe::TwoWay \
       -M DFWpm::BotPlugin \
       -M DFWpm::BotPlugin::Spelling \
       -M DFWpm::BotPlugin::Dictionary \
       -M DFWpm::BotPlugin::Greeter \
       -o borgbot dfw_borgbot.pl
