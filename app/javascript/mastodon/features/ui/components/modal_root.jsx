import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { Helmet } from 'react-helmet';

import Base from 'mastodon/components/modal_root';
import { AltTextModal } from 'mastodon/features/alt_text_modal';
import {
  DomainMuteModal,
  MuteModal,
  BlockModal,
  DomainBlockModal,
  ReportModal,
  EmbedModal,
  ListAdder,
  CompareHistoryModal,
  FilterModal,
  InteractionModal,
  SubscribedLanguagesModal,
  ClosedRegistrationsModal,
  IgnoreNotificationsModal,
  AnnualReportModal,
} from 'mastodon/features/ui/util/async-components';

import BundleContainer from '../containers/bundle_container';

import { ActionsModal } from './actions_modal';
import AudioModal from './audio_modal';
import { BoostModal } from './boost_modal';
import {
  ConfirmationModal,
  ConfirmDeleteStatusModal,
  ConfirmDeleteListModal,
  ConfirmReplyModal,
  ConfirmEditStatusModal,
  ConfirmUnfollowModal,
  ConfirmClearNotificationsModal,
  ConfirmLogOutModal,
  ConfirmFollowToListModal,
  ConfirmMissingAltTextModal,
} from './confirmation_modals';
import { ImageModal } from './image_modal';
import MediaModal from './media_modal';
import { ModalPlaceholder } from './modal_placeholder';
import VideoModal from './video_modal';

export const MODAL_COMPONENTS = {
  'MEDIA': () => Promise.resolve({ default: MediaModal }),
  'VIDEO': () => Promise.resolve({ default: VideoModal }),
  'AUDIO': () => Promise.resolve({ default: AudioModal }),
  'IMAGE': () => Promise.resolve({ default: ImageModal }),
  'BOOST': () => Promise.resolve({ default: BoostModal }),
  'CONFIRM': () => Promise.resolve({ default: ConfirmationModal }),
  'CONFIRM_DELETE_STATUS': () => Promise.resolve({ default: ConfirmDeleteStatusModal }),
  'CONFIRM_DELETE_LIST': () => Promise.resolve({ default: ConfirmDeleteListModal }),
  'CONFIRM_REPLY': () => Promise.resolve({ default: ConfirmReplyModal }),
  'CONFIRM_EDIT_STATUS': () => Promise.resolve({ default: ConfirmEditStatusModal }),
  'CONFIRM_UNFOLLOW': () => Promise.resolve({ default: ConfirmUnfollowModal }),
  'CONFIRM_CLEAR_NOTIFICATIONS': () => Promise.resolve({ default: ConfirmClearNotificationsModal }),
  'CONFIRM_LOG_OUT': () => Promise.resolve({ default: ConfirmLogOutModal }),
  'CONFIRM_FOLLOW_TO_LIST': () => Promise.resolve({ default: ConfirmFollowToListModal }),
  'CONFIRM_MISSING_ALT_TEXT': () => Promise.resolve({ default: ConfirmMissingAltTextModal }),
  'MUTE': MuteModal,
  'DOMAIN_MUTE': DomainMuteModal,
  'BLOCK': BlockModal,
  'DOMAIN_BLOCK': DomainBlockModal,
  'REPORT': ReportModal,
  'ACTIONS': () => Promise.resolve({ default: ActionsModal }),
  'EMBED': EmbedModal,
  'FOCAL_POINT': () => Promise.resolve({ default: AltTextModal }),
  'LIST_ADDER': ListAdder,
  'COMPARE_HISTORY': CompareHistoryModal,
  'FILTER': FilterModal,
  'SUBSCRIBED_LANGUAGES': SubscribedLanguagesModal,
  'INTERACTION': InteractionModal,
  'CLOSED_REGISTRATIONS': ClosedRegistrationsModal,
  'IGNORE_NOTIFICATIONS': IgnoreNotificationsModal,
  'ANNUAL_REPORT': AnnualReportModal,
};

export default class ModalRoot extends PureComponent {

  static propTypes = {
    type: PropTypes.string,
    props: PropTypes.object,
    onClose: PropTypes.func.isRequired,
    ignoreFocus: PropTypes.bool,
  };

  state = {
    backgroundColor: null,
  };

  setBackgroundColor = color => {
    this.setState({ backgroundColor: color });
  };

  renderLoading = () => {
    const { onClose } = this.props;

    return <ModalPlaceholder loading onClose={onClose} />;
  };

  renderError = (props) => {
    const { onClose } = this.props;

    return <ModalPlaceholder {...props} onClose={onClose} />;
  };

  handleClose = (ignoreFocus = false) => {
    const { onClose } = this.props;
    const message = this._modal?.getCloseConfirmationMessage?.();
    onClose(message, ignoreFocus);
  };

  setModalRef = (c) => {
    this._modal = c;
  };

  render() {
    const { type, props, ignoreFocus } = this.props;
    const { backgroundColor } = this.state;
    const visible = !!type;

    return (
      <Base backgroundColor={backgroundColor} onClose={this.handleClose} ignoreFocus={ignoreFocus}>
        {visible && (
          <>
            <BundleContainer fetchComponent={MODAL_COMPONENTS[type]} loading={this.renderLoading} error={this.renderError} renderDelay={200}>
              {(SpecificComponent) => {
                return <SpecificComponent {...props} onChangeBackgroundColor={this.setBackgroundColor} onClose={this.handleClose} ref={this.setModalRef} />;
              }}
            </BundleContainer>

            <Helmet>
              <meta name='robots' content='noindex' />
            </Helmet>
          </>
        )}
      </Base>
    );
  }

}
