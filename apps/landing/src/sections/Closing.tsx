import { AppCta } from '../components/StoreBadges';
import { photos } from '../components/primitives';
import { useSite } from '../context';

/** Kết (V8: home 735:6497, Năm đầu đời 737:8276, Chặng 2 738:7445): a dark card with the title,
 *  the download component and a photo (hidden on mobile, as drawn). Target of every "Bắt đầu". */
export function Closing() {
  const { c } = useSite();
  return (
    <section id="tai-app" className="closing" aria-labelledby="closing-title">
      <div className="closing__card container reveal">
        <div className="closing__copy">
          <h2 id="closing-title" className="closing__title">
            {c.closing.title}
          </h2>
          <p className="closing__sub">{c.closing.sub}</p>
          <AppCta tone="dark" />
        </div>
        <span className="closing__photo" aria-hidden="true">
          <img src={photos.sun} alt="" loading="lazy" decoding="async" />
        </span>
      </div>
    </section>
  );
}
