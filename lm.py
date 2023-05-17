#!/usr/bin/env python3
import gpt4all

gptj = gpt4all.GPT4All("ggml-gpt4all-j-v1.3-groovy")
messages = [{"role": "user", "name": "Seppe", "content": "What is your name?"}]
gptj.chat_completion(messages)
