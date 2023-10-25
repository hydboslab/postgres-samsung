import psycopg2
import sys, subprocess
import time, threading
import os, random
import argparse
import pathlib, datetime
import json
import fileinput
import random
import re
import glob

# TODO
# - config file for the NDP needs kernel path

# Run mode
VANILLA = 0

SHORT_TRX = 0
LONG_TRX = 1

def log(s):
    print('[Microbench] {}'.format(s))

def run_script(script, params, desc, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT):
    command = [script]
    command.extend(params)
    log('{} start!'.format(desc))
    subprocess.run(args=command,
            stdout=stdout, stderr=stderr,
            check=True)
    log('{} finished!'.format(desc))

def create_config_file(config_file, new_config_file, args):
    replacers = [['port = 5678', 'port = {}'.format(args.pgsql_port)]]

    # After init server, the config file is copied into the data directory
    with open(new_config_file, 'w') as new_config:
        with open(config_file, 'r') as src_config:
            for line in src_config:
                for replacer in replacers:
                    line = line.replace(replacer[0], replacer[1])
                new_config.write(line)


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
        fp.write('0') # for graph consistency


# Sysbench
class SysbenchWorker(threading.Thread):
    def __init__(self, sysbench_script, sysbench_dir, result_file, args):
        threading.Thread.__init__(self)

        self.sysbench_script = sysbench_script
        self.result_file = result_file
        self.args = args
        self.options = self.parse_params(args)

        self.sysbench_dir = sysbench_dir

        src_dir = os.path.join(sysbench_dir, 'src')
        lua_file = os.path.join(src_dir, 'lua', args.lua)

        self.params = ['--src-dir={}'.format(src_dir),
                       '--sysbench-dir={}'.format(self.sysbench_dir),  
                       '--lua={}'.format(lua_file)]
        self.params.extend(self.options)

        params = self.params.copy()
        params.append('--mode=cleanup')
        run_script(self.sysbench_script, params, 'Sysbench cleanup')

        params = self.params.copy()
        params.append('--mode=prepare')
        run_script(self.sysbench_script, params, 'Sysbench prepare')

    def run(self):
        params = self.params.copy()
        params.append('--mode=run')
        with open(self.result_file, 'w') as f:
            run_script(self.sysbench_script, params, 'Sysbench run', stdout=f, stderr=subprocess.DEVNULL)

    def parse_params(self, args):
        # TODO: kind of a hack
        options = []
        for k, v in vars(args).items():
            if 'lua' not in k:
                options.append('--{}={}'.format(k,str(v)).replace('_', '-'))
        return options

# Client for running long joins on sysbench
class Client(threading.Thread):
    def __init__(self, client_id, autocommit, result_file, args):
        threading.Thread.__init__(self)

        self.client_id = client_id
        self.autocommit = autocommit
        self.result_file = result_file
        self.args = args

        self.tables = int(args.tables)
        self.join_tables = int(args.join_tables)

        self.db = self.make_connector()
        self.cursor = self.db.cursor()
        self.end = False

        if self.client_id == 0 and self.autocommit == False:
            log(self.make_query())

    def terminate(self):
        if self.end is False:
            self.end = True

    def run(self):
        self.db.autocommit = self.autocommit

        # TODO: Please update the method used to join, and then verify the output.
        self.cursor.execute('SET enable_mergejoin = on;')
        self.cursor.execute('SET enable_nestloop = off;')
        self.cursor.execute('SET enable_hashjoin = off;')
        
        #self.cursor.execute('SET enable_bitmapscan = off;')
        #self.cursor.execute('SET enable_indexscan = off;')
        #self.cursor.execute('SET enable_indexonlyscan = off;')
        #self.cursor.execute('SET enable_tidscan = off;')
        #self.cursor.execute('SET enable_seqscan = on;')

        if self.client_id == 0 and self.autocommit == True:
            with open('query_plan.data', 'w') as f:
                self.cursor.execute('explain ' + self.make_query())
                plan = self.cursor.fetchall()
                for line in plan:
                    f.write(line[0] + '\n')

        with open(self.result_file, 'w') as f:
            epoch = time.perf_counter()

            while not self.end: # ends looping in terminate()
                start_time = time.perf_counter()

                query = self.make_query()
                self.cursor.execute(query)
                self.cursor.fetchall()

                end_time = time.perf_counter()

                results = f'{(start_time - epoch + self.args.time_oltp_only):.3f} {(end_time - epoch + self.args.time_oltp_only):.3f}\n'
                f.write(results)
                f.flush()

            self.db.commit()
            self.cursor.close()
            self.db.close()

    def make_query(self):
        rand_tables = random.sample(range(1, self.tables + 1), self.join_tables)

        # TODO: is it fair to sort it?
        rand_tables.sort()

        from_stmt = ['sbtest{}'.format(str(i)) for i in rand_tables] # sbtest1
        where_stmt = ['{}.id'.format(i) for i in from_stmt] # sbtest1.id
        predicate_value = int(int(args.table_size) * args.selectivity)
        predicate = ['{}.k <= {}'.format(i, predicate_value) for i in from_stmt[:1]]
        predicate = ' and '.join(predicate)

        select_stmt = [i + '.k' for i in from_stmt]
        select_stmt = ' + '.join(select_stmt)
        select_stmt = 'SUM({})'.format(select_stmt)

        from_stmt = ', '.join(from_stmt)

        where_stmt = \
                ['{} = {}'.format(where_stmt[i], where_stmt[i+1]) \
                for i in range(len(where_stmt) - 1)]
        where_stmt = ' and '.join(where_stmt)
        if self.client_id == 0:
            where_stmt = '{} and {}'.format(where_stmt, predicate)

        query = 'SELECT {} FROM {} WHERE {};'.format(select_stmt, from_stmt, where_stmt)

        return query

    def make_connector(self):
        return psycopg2.connect(
                host=self.args.pgsql_host,
                dbname=self.args.pgsql_db,
                user=self.args.pgsql_user,
                port=self.args.pgsql_port)


# Space checker for data size
class SpaceChecker(threading.Thread):
    def __init__(self, result_file, data_dir, args):
        threading.Thread.__init__(self)

        self.result_file = result_file
        self.data_dir = data_dir
        self.args = args

        self.end = False

    def terminate(self):
        if self.end is False:
            self.end = True

    def run(self):
        default_size = int(str(subprocess.check_output([f'du -sb {self.data_dir}/base/16*'], shell=True).decode('utf-8')).split()[0])

        with open(self.result_file, 'w') as f:
            epoch = time.perf_counter()

            while not self.end: # ends looping in terminate()
                current_time = time.perf_counter()

                data_size = int(str(subprocess.check_output([f'du -sb {self.data_dir}/base/16*'], shell=True).decode('utf-8')).split()[0])

                results = f'{(current_time - epoch):.3f} {data_size - default_size}\n'
                f.write(results)
                f.flush()
                time.sleep(1)

# Client for checking temp file spills
class TempSpillChecker(threading.Thread):
    def __init__(self, result_file, args):
        threading.Thread.__init__(self)

        self.result_file = result_file
        self.args = args

        self.query ='SELECT temp_bytes, temp_files FROM pg_stat_database where datname = \'{}\';'.format(args.pgsql_db)
        #self.query ='SELECT datname, temp_bytes, temp_files FROM pg_stat_database;'

        self.db = self.make_connector()
        self.cursor = self.db.cursor()
        self.end = False

    def terminate(self):
        if self.end is False:
            self.end = True

    def run(self):
        self.db.autocommit = True
        self.cursor.execute(self.query)
        result = self.cursor.fetchone()

        with open(self.result_file, 'w') as f:
            epoch = time.perf_counter()

            while not self.end: # ends looping in terminate()
                current_time = time.perf_counter()

                self.cursor.execute(self.query)
                result = self.cursor.fetchone()

                temp_bytes = result[0]
                temp_files = result[1]

                end_time = time.perf_counter()

                results = f'{(current_time - epoch):.3f} {temp_bytes} {temp_files}\n'
                f.write(results)
                f.flush()

                time.sleep(1)

            self.db.commit()
            self.cursor.close()
            self.db.close()

    def make_connector(self):
        return psycopg2.connect(
                host=self.args.pgsql_host,
                dbname=self.args.pgsql_db,
                user=self.args.pgsql_user,
                port=self.args.pgsql_port)

# Space checker for temp file size
class TempChecker(threading.Thread):
    def __init__(self, result_file, data_dir, args):
        threading.Thread.__init__(self)

        self.result_file = result_file
        self.data_dir = data_dir
        self.args = args

        self.end = False

    def terminate(self):
        if self.end is False:
            self.end = True

    def run(self):
        with open(self.result_file, 'w') as f:
            epoch = time.perf_counter()

            while not self.end: # ends looping in terminate()
                current_time = time.perf_counter()

                try:
                    data_size = int(str(subprocess.check_output([f'du -sb {self.data_dir}/base/pgsql_tmp'], shell=True).decode('utf-8')).split()[0])
                except:
                    data_size = 0

                results = f'{(current_time - epoch):.3f} {data_size}\n'
                f.write(results)
                f.flush()
                time.sleep(1)

def run_exp(args, mode):
    # Directory paths
    base_dir       = os.getcwd()
    sysbench_base  = os.path.join(base_dir, 'sysbench')
    src_dir        = os.path.join(base_dir, 'postgres')
    install_dir    = os.path.join(base_dir, 'pgsql')
    data_dir       = os.path.join(base_dir, 'data')
    config_dir     = os.path.join(base_dir, 'config')
    result_base    = os.path.join(base_dir, 'results')
    script_dir     = os.path.join(base_dir, 'scripts')
    sysbench_dir   = os.path.join(base_dir, 'sysbench')
    result_dir     = os.path.join(result_base, datetime.datetime.utcnow().strftime('%y-%m-%d_%H:%M:%S'))
    recent_dir     = os.path.join(result_base, 'recent')
    extension_dir  = os.path.join(src_dir, 'contrib')
    bin_dir        = os.path.join(install_dir, 'bin')
    lib_dir        = os.path.join(install_dir, 'lib')
    perf_dir       = os.path.join(base_dir, 'logs')

    # File paths
    args_dump = os.path.join(result_dir, 'args.txt')
    config_file = os.path.join(config_dir, 'postgresql.conf')
    new_config_file = os.path.join(data_dir, 'postgresql.conf')
    install_script = os.path.join(script_dir, 'install.sh')
    sysbench_install_script = os.path.join(script_dir, 'install_sysbench.sh')
    sysbench_script = os.path.join(script_dir, 'sysbench.sh')
    plot_script = os.path.join(script_dir, 'plot.sh')
    init_script = os.path.join(script_dir, 'init_server.sh')
    start_script = os.path.join(script_dir, 'start_server.sh')
    create_script = os.path.join(script_dir, 'create_db.sh')
    stop_script = os.path.join(script_dir, 'stop_server.sh')
    pg_hint_script = os.path.join(script_dir, 'pg_hint.sh')
    logfile = os.path.join(data_dir, 'logfile')
    sysbench_file = os.path.join(result_dir, 'sysbench.data')
    tps_file = os.path.join(result_dir, 'tps.data')
    space_file = os.path.join(result_dir, 'space.data')
    temp_file = os.path.join(result_dir, 'tempfile.data')
    png_file = os.path.join(result_dir, 'result.png')
    gpi_file = os.path.join(script_dir, 'sysbench.gpi')
    postmaster_pid_file = os.path.join(data_dir, 'postmaster.pid')

    # Create result directory
    pathlib.Path(result_dir).mkdir(parents=True, exist_ok=True)

    # Create a link of result directory to 'recent' directory for convenience
    os.system("rm -rf {}".format(recent_dir))
    os.system("ln -rs {} {}".format(result_dir, recent_dir))

    # Dump args
    with open(args_dump, 'w') as f:
        json.dump(args.__dict__, f, indent=2)

    log('{} experiment start!'.format(mode))

    # Compile sysbench code
    if args.install_sysbench:
        params = ['--sysbench-base-dir={}'.format(sysbench_base)]
        run_script(sysbench_install_script, params, 'Compile sysbench')

    # Install postgres (i.e., compile, install, etc.)
    if args.install:
        params = ['--base-dir={}'.format(base_dir),
                  '--src-dir={}'.format(src_dir),
                  '--install-dir={}'.format(install_dir),
                  '--compile-option={}'.format(args.compile_option),
                  '--lib-option={}'.format(args.lib_option),
                  '--extension-dir={}'.format(extension_dir)]
        if args.gdb:
            params.append('--gdb')
        run_script(install_script, params, desc='Compile database', stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

    # Init DB (i.e., initdb)
    params = ['--bin-dir={}'.format(bin_dir),
              '--lib-dir={}'.format(lib_dir),
              '--data-dir={}'.format(data_dir),
              '--config-file={}'.format(config_file)]
    run_script(init_script, params, desc='Init DB')

    # Create a new config file according to the args
    create_config_file(config_file, new_config_file, args)

    # Leave a copy of the config file to result directory
    os.system('cp {} {}'.format(new_config_file, result_dir))

    # Start server
    params = ['--bin-dir={}'.format(bin_dir),
              '--data-dir={}'.format(data_dir),
              '--logfile={}'.format(logfile)]
    run_script(start_script, params, desc='Start server')

    # Create DB (i.e., createdb)
    params = ['--bin-dir={}'.format(bin_dir),
              '--host={}'.format(args.pgsql_host),
              '--database={}'.format(args.pgsql_db),
              '--user={}'.format(args.pgsql_user),
              '--port={}'.format(args.pgsql_port)]
    run_script(create_script, params, desc='Create DB')

    params = ['--bin-dir={}'.format(bin_dir),
              '--port={}'.format(args.pgsql_port),
              '--database={}'.format(args.pgsql_db)]
    #run_script(pg_hint_script, params, desc='Install pg_hint')

    # Sysbench
    sys_worker = SysbenchWorker(sysbench_script=sysbench_script, sysbench_dir=sysbench_dir, result_file=sysbench_file, args=args)
    space_checker = SpaceChecker(result_file=space_file, data_dir=data_dir, args=args)
    #temp_checker = TempSpillChecker(result_file=temp_file, args=args)
    temp_checker = TempChecker(result_file=temp_file, data_dir=data_dir, args=args)
    short_client = [Client(client_id=i, autocommit=True, result_file=os.path.join(result_dir, f'latency_short_{i}.data'), args=args) \
            for i in range(0, args.num_short_olap)]
    long_client = [Client(client_id=i, autocommit=False, result_file=os.path.join(result_dir, f'latency_long_{i}.data'), args=args) \
            for i in range(0, args.num_long_olap)]

    log('<Phase 1> Warmup ({} sec) -> OLTP only ({} sec)'.format(args.warmup_time, args.time_oltp_only))
    sys_worker.start()
    space_checker.start()
    temp_checker.start()
    if args.warmup_time != 0:
        time.sleep(args.warmup_time)

    time.sleep(args.time_oltp_only)

    both_time = args.time - (args.time_oltp_only + args.time_olap_only)
    log('<Phase 2> Run OLAP + OLTP together ({} sec)'.format(both_time))

    for client in short_client:
        client.start()
    for client in long_client:
        client.start()
    time.sleep(both_time)

    log('<Phase 3> Run OLAP only ({} sec)'.format(args.time_olap_only))
    time.sleep(args.time_olap_only)

    sys_worker.join()
    space_checker.terminate()
    space_checker.join()
    temp_checker.terminate()
    temp_checker.join()

    # Parse TPS from results/recent/sysbench.data file
    parse_tps(sysbench_file, tps_file)

    for client in short_client:
        client.terminate()
    for client in long_client:
        client.terminate()
    for client in short_client:
        client.join()
    for client in long_client:
        client.join()

    # Stop server
    params = ['--bin-dir={}'.format(bin_dir),
              '--data-dir={}'.format(data_dir)]
    run_script(stop_script, params, desc='Stop server')

    # Plot using the result files
    params = ['--gpi={}'.format(gpi_file),
              '--png-file={}'.format(png_file),
              '--latency-short-file={}'.format(short_client[0].result_file),
              '--latency-long-file={}'.format(long_client[0].result_file),
              '--temp-file={}'.format(temp_file),
              '--tps-file={}'.format(tps_file),
              '--space-file={}'.format(space_file)]
    run_script(plot_script, params, desc='Plot data')

    # Copy necessary files
    os.system('cp {} {}'.format(logfile, result_dir))

    selectivity_result_dir = os.path.join(base_dir, 'selectivity', mode, str(int(args.selectivity * 100)))
    pathlib.Path(selectivity_result_dir).mkdir(parents=True, exist_ok=True)
    recent_files = os.path.join(recent_dir, '*')
    os.system('cp -r {} {}'.format(recent_files, selectivity_result_dir))

    log('{} experiment finished!'.format(mode))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Sysbench Arguments...')

    # Parser for each context
    pgsql_parser = parser.add_argument_group('pgsql', 'PostgreSQL options')
    sysbc_parser = parser.add_argument_group('sysbench', 'Sysbench options')
    options_parser = parser.add_argument_group('options', 'Other options')

    # PostgreSQL
    pgsql_parser.add_argument('--pgsql-host', default='localhost', help='pgsql host')
    pgsql_parser.add_argument('--pgsql-db', default='sbtest', help='pgsql database')
    pgsql_parser.add_argument('--pgsql-user', default='sdb', help='pgsql user')
    pgsql_parser.add_argument('--pgsql-port', default='5678', help='pgsql port number')

    # Sysbench
    sysbc_parser.add_argument('--install-sysbench', default=False, action='store_true', help='intall sysbench?')
    sysbc_parser.add_argument('--report-interval', default=1, help='report interval. default 1 second')
    sysbc_parser.add_argument('--secondary', default='off', help='default off')
    sysbc_parser.add_argument('--create-secondary', default='false', help='default = false')
    sysbc_parser.add_argument('--time', type=int, default=60, help='total execution time')
    sysbc_parser.add_argument('--threads', type=int, default=4, help='number of threads')
    sysbc_parser.add_argument('--tables', type=int, default=12, help='number of tables')
    sysbc_parser.add_argument('--join-tables', type=int, default=4, help='number of tables to join for each query')
    sysbc_parser.add_argument('--table-size', type=int, default=200000, help='sysbench table size')
    sysbc_parser.add_argument('--warmup-time', type=int, default=0, help='sysbench warmup time')
    sysbc_parser.add_argument('--rand-type', default='zipfian')
    sysbc_parser.add_argument('--rand-zipfian-exp', default='0.0')
    sysbc_parser.add_argument('--lua', default='oltp_update_non_index.lua',\
            help='lua script, default: oltp_update_non_index')

    # Others
    options_parser.add_argument('--install', default=False, action='store_true', help='execute reinstallation or not')
    options_parser.add_argument('--run-mode', type=int, default=0, help='0: Vanilla')
    options_parser.add_argument('--compile-option', default='', help='compile options')
    options_parser.add_argument('--lib-option', default='', help='lib options')
    options_parser.add_argument('--gdb', default=False, action='store_true', help='compile with gdb enabled')

    options_parser.add_argument('--time-olap-only', type=int, default=0, help='OLAP exclusive time')
    options_parser.add_argument('--time-oltp-only', type=int, default=0, help='OLTP exclusive time')
    options_parser.add_argument('--num-short-olap', type=int, default=1, help='# of OLAP queries w\o autocommit')
    options_parser.add_argument('--num-long-olap', type=int, default=1, help='# of OLAP queries w\ autocommit')
    options_parser.add_argument('--selectivity', type=float, default=0.1, help='predicate for selectivity')

    args=parser.parse_args()

    if args.run_mode == VANILLA:
        mode_str = 'vanilla'
    else:
        exit(-1)

    log('{} experiment start!'.format(str(args.selectivity)))
    run_exp(args, mode_str)
    log('{} experiment finished!'.format(str(args.selectivity)))

