import { AppCta } from '../components/StoreBadges';
import { useSite } from '../context';

/** Kết (V9: home 785:7872, Năm đầu đời 785:9895, Chặng 2 785:10856): a centred dark card with the
 *  title, the official store badges and a caption; no photo. Target of every "Bắt đầu". */
export function Closing() {
  const { c } = useSite();
  return (
    <section id="tai-app" className="closing" aria-labelledby="closing-title">
      <div className="closing__card container reveal">
        <h2 id="closing-title" className="closing__title">
          {c.closing.title}
        </h2>
        <p className="closing__sub">{c.closing.sub}</p>
        <AppCta tone="dark" />
      </div>
    </section>
  );
}
