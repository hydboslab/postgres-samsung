import re
import glob


# TPS extract
def lines_that_contain(string, fp):
    return [line for line in fp if string in line]

def extract_tps(lines):
    tps_regex = re.compile(r'tps: (\d+\.\d+)')
    str_result = [tps_regex.search(line).group(1) for line in lines]
    result = [float(tps) for tps in str_result]
    return result

def parse_tps(infile, outfile):
    parsed_lines = []
    with open(infile, 'r') as fp:
        parsed_lines.extend(lines_that_contain('tps:', fp))

    tps_list = extract_tps(parsed_lines)

    with open(outfile, 'w') as fp:
        for tps in tps_list:
            fp.write('%s\n' % tps)
        fp.write('0\n') # for graph consistency

def extract_err(lines):
    err_regex = re.compile(r"err/s: (\d+\.\d+)")
    str_result = [err_regex.search(line).group(1) for line in lines]
    result = [float(err) for err in str_result]
    return result

def parse_err(infile, outfile):
    parsed_lines = []
    with open(infile, 'r') as fp:
        parsed_lines.extend(lines_that_contain("err/s:", fp))

    err_list = extract_err(parsed_lines)

    with open(outfile, 'w') as fp:
        for err in err_list:
            fp.write('%s\n' % err)
        fp.write('0\n') # for graph consistency

if __name__ == '__main__':
    parse_tps('sysbench.data', 'tps.data')
    parse_err('sysbench.data', 'err.data')

