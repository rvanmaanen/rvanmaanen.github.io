import time
import sys
import signal

aborted = [False]

def handle_abort(signum, frame):
    aborted[0] = True

def main():
    print("\nYou have 10 seconds to abort this process (Ctrl+C or send SIGTERM) if you want to stop the push workflow.")
    print("If you do nothing, the workflow will continue and your changes will be committed and pushed.")
    print("If you abort, the workflow will stop and nothing will be pushed.\n")
    sys.stdout.flush()
    signal.signal(signal.SIGINT, handle_abort)
    signal.signal(signal.SIGTERM, handle_abort)
    start = time.time()
    while time.time() - start < 10:
        time.sleep(0.1)
        if aborted[0]:
            print("\nAborted by user. Exiting with code 1.")
            sys.exit(1)
    print("\nNo abort detected. Proceeding with the workflow. Exiting with code 0.")
    sys.exit(0)

if __name__ == "__main__":
    main()
