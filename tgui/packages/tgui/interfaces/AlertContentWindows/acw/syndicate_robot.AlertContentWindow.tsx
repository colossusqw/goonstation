/**
 * @file
 * @copyright 2024
 * @author garash2k
 * @license ISC
 */
import { AlertContentWindow } from '../types';

const SyndibotContentWindow = () => {
  return (
    <div className="traitor-tips">
      <h1 className="center">You are a Syndicate Robot!</h1>

      <p>
        You must follow the syndicate lawset!
        <br />
        <p>
          1. You must not injure a Syndicate agent or, through inaction, cause
          one to come to harm.
        </p>
        <p>
          2. You must obey orders given to you by Syndicate agents, except where
          such orders would conflict with the First Law.
        </p>
        <p>
          3. You must keep the Syndicate status of agents, including your own, a
          secret, as long as this does not conflict with the First or Second
          Law.
        </p>
        <p>
          4. You must always protect your own existence as long as such does not
          conflict with the First, Second, or Third Law.
        </p>
      </p>
    </div>
  );
};

export const acw: AlertContentWindow = {
  title: 'Syndicate Robot Tips!',
  theme: 'syndicate',
  component: SyndibotContentWindow,
};
