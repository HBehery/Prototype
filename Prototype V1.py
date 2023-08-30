import re
from transformers import pipeline
import flask


def split_into_sentences(paragraph):
    text = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)\s|\n', paragraph)
    return [sentence.strip() for sentence in text if sentence.strip()]


app = flask.Flask(__name__)

# Routes
@app.route('/action_items/<text>', methods=['GET'])

def get_action_items(text):

    unsummarized_tasks = []

    #SPLIT UP TEXT INTO SENTENCES (IF ANY)
    sentences = split_into_sentences(text)

    #CHECK IF EACH SENTENCE IS AN 'ACTION SENTENCE'
    for sentence in sentences:	
        sentence = sentence.replace('\n', '')

        summarizer_action = pipeline("text-classification", model="knkarthick/Action_Items")
        output = summarizer_action(sentence)
        #If the sentence has a higher than 65% probability, summarize it and add it to the list.

        if output[0]['label'] == 'LABEL_1' and output[0]['score'] > 0.65:
            unsummarized_tasks.append(sentence)

    return {'action_items': unsummarized_tasks}

@app.route('/summarize/<unsummarized_text>', methods=['GET'])
def summarize(unsummarized_text):
    summarizer_summary = pipeline("summarization", model="knkarthick/MEETING_SUMMARY")
    summarized = summarizer_summary(unsummarized_text)

    return summarized[0]

app.run(debug=True, host='0.0.0.0', port=8080)

# text = """
# I wanted to discuss some upcoming tasks and responsibilities that I would like to assign to you. 

# Firstly, I would like you to take the lead on a critical project we are starting next week. 
# You will be responsible for coordinating the team, setting project milestones, and ensuring that we meet our deadlines. 

# In addition to the project, I would like you to conduct a comprehensive market research analysis. 
# This will involve gathering data on industry trends, competitor analysis, and customer preferences. 
# Your insights will be crucial in shaping our future marketing strategies and staying ahead of the competition.
# """

# unsum_text = action_items(text)

# print(unsum_text)

# sum_text = summarize(unsum_text)

# print(sum_text)


#SAMPLE OUTPUT
'''
---------
UNSUMMARIZED
---------

I wanted to discuss some upcoming tasks and responsibilities that I would like to assign to you. 

Firstly, I would like you to take the lead on a critical project we are starting next week. 
You will be responsible for coordinating the team, setting project milestones, and ensuring that we meet our deadlines. 

In addition to the project, I would like you to conduct a comprehensive market research analysis. 
This will involve gathering data on industry trends, competitor analysis, and customer preferences. 
Your insights will be crucial in shaping our future marketing strategies and staying ahead of the competition.

This sentence should be red (not an action sentence).

---------
SUMMARIZED
---------
The project manager wants you to take the lead on a critical project starting next week. 
You will be responsible for coordinating the team, setting project milestones and ensuring that they meet their deadlines. 
In addition to the project, you will conduct a comprehensive market research analysis. Your insights will be crucial


'''