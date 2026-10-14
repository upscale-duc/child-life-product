import firstSchoolDay from '../assets/photos/first-school-day.jpg';
import preschoolDrawing from '../assets/photos/preschool-drawing.jpg';
import schoolAgeReading from '../assets/photos/school-age-reading.jpg';
import toddlerBlocks from '../assets/photos/toddler-blocks.jpg';
import teddyEight from '../assets/photos/teddy-eight-months.jpg';
import teddyCouch from '../assets/photos/teddy-one-couch.jpg';
import teddyStroller from '../assets/photos/teddy-one-stroller.jpg';
import teddyTwoMonths from '../assets/photos/teddy-two-months.jpg';
import teddyYawn from '../assets/photos/teddy-newborn-yawn.jpg';
import twelvePainting from '../assets/photos/twelve-painting.jpg';

/** Real photographs for the image slots of the v5b home (28-landing-v5b-home §7). The first year
 *  is one baby ("Teddy", Minnie Zhou's album); later stages are other children. Licensed stock
 *  photos; sources and licences in assets/photos/CREDITS.md. */
export const scenes = {
  /** Chặng 2 card: a toddler playing (1–3 years). */
  toddler: toddlerBlocks,
  /** Chặng 3 card: a preschooler drawing (3–6 years). */
  preschool: preschoolDrawing,
  /** Chặng 4 card: a school-age child reading (6–12 years). */
  schoolAge: schoolAgeReading,
  /** Band "1 tuổi": Teddy at one. */
  firstBirthday: teddyStroller,
  /** Band "6 tuổi": first day of school. */
  firstSchoolDay,
  /** Band "12 tuổi": a passion of their own. */
  dreams: twelvePainting,
  /** "Xem đầy đủ năm đầu đời": Teddy holding a parent's finger. */
  parentNewborn: teddyTwoMonths,
  /** Memory video "Lần đầu biết lẫy": Teddy at eight months. */
  firstYearVideo: teddyEight,
  /** "Ngày ấy và bây giờ": Teddy as a newborn … */
  thenBaby: teddyYawn,
  /** … and around one year old. */
  nowBaby: teddyCouch,
};
export type Scene = keyof typeof scenes;
