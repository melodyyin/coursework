def label( self, data ):
    ''' Find the most likely labels for the sequence of data
        This is an implementation of the Viterbi algorithm  '''
    # data is the list of strokes, represented by features (evidence)
    # Viterbi
    ####Init: prior*evidence
    ####Rest: prev*(transition*evidence) ; there will be 'states' probs per state - pick largest one
    ####Repeat until all strokes are covered 
    # Priors: self.prior[STATE]
    # Transition: self.transitions[FROM-STATE][TO-STATE]
    # Emission: self.emissions[STATE][FEATURE][EVIDENCE] ; (short, long)

    # Part 1 Viterbi Testing Example
    # Class example 
    # my_states = ['sunny', 'cloudy', 'rainy']
    # my_features = ['groundcond']
    # my_evidence = [0, 2, 3] #['dry', 'damp', 'soggy']
    # my_priors = {
    #     'sunny': 0.63,
    #     'cloudy': 0.17,
    #     'rainy': 0.20
    # }
    # my_transitions = {
    #     'sunny': {'sunny': 0.5, 'cloudy': 0.375, 'rainy': 0.125},
    #     'cloudy': {'sunny': 0.25, 'cloudy': 0.125, 'rainy': 0.625},
    #     'rainy': {'sunny': 0.25, 'cloudy': 0.375, 'rainy': 0.375}
    # }
    # my_emissions = {
    #     'sunny': {'groundcond': [0.6, 0.2, 0.15, 0.05]}, 
    #     'cloudy': {'groundcond': [0.25, 0.25, 0.25, 0.25]}, 
    #     'rainy': {'groundcond': [0.05, 0.1, 0.35, 0.5]}
    #     }

    my_states = self.states
    my_features = self.featureNames
    my_evidence = data
    my_priors = self.priors
    my_transitions = self.transitions
    my_emissions = self.emissions 

    path = []
    init = {}

    # first 
    t = 0
    for s in my_states:
        features_prob = 1     # initialize to multiply over all features 
        for f in my_features:
            features_prob *= my_emissions[s][f][my_evidence[t][f]]

        init[s] = my_priors[s] * features_prob  # init = prior*evidence 

    path.append(max(init.items(), key=lambda x: x[1])[0])   # choose the state with the highest likelihood 

    # rest 
    t = 1
    prev = copy.deepcopy(init)
    curr_compare = {}
    curr = {}
    while (t < len(my_evidence)):
        # each of the current states need a probability 
        for to_state in my_states:
            # loop over the prev states
            for from_state in my_states:
                features_prob = 1
                for f in my_features:
                    features_prob *= my_emissions[to_state][f][my_evidence[t][f]]

                # find all probs of (to_state, from_state) where to_state is fixed 
                curr_compare[from_state] = prev[from_state] * my_transitions[from_state][to_state] * features_prob
            curr[to_state] = max(curr_compare.items(), key=lambda x: x[1])[1]   # for each to_state, get the max prob of being there

        path.append(max(curr.items(), key=lambda x: x[1])[0])   # add the most likely to_state to path

        # refresh
        prev = copy.deepcopy(curr)
        t += 1

    return path