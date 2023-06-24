from nnmnkwii.io import hts
import sys
binary, continuous = hts.load_question_set(sys.argv[1])
in_dim = len(binary) + len(continuous)